import os
import uuid
import logging
from dataclasses import dataclass
from pathlib import Path
from fastapi import UploadFile
from app.config.settings import settings
from starlette.concurrency import run_in_threadpool

logger = logging.getLogger(__name__)

@dataclass(frozen=True)
class StorageUploadResult:
    url: str
    public_id: str | None = None


class StorageService:
    @staticmethod
    def _cloudinary_transformations() -> list[dict[str, str | int]]:
        return [
            {"width": 512, "height": 512, "crop": "fill", "gravity": "auto"},
            {"quality": "auto", "fetch_format": "auto"},
        ]

    @staticmethod
    def get_provider() -> str:
        return settings.storage_provider.lower()

    @classmethod
    async def upload_file(cls, file: UploadFile, upload_dir: str) -> str:
        result = await cls.upload_file_with_metadata(file, upload_dir)
        return result.url

    @classmethod
    async def upload_file_with_metadata(
        cls, file: UploadFile, upload_dir: str
    ) -> StorageUploadResult:
        provider = cls.get_provider()
        filename = file.filename or "avatar.png"
        
        # Read file contents for remote storage or validation
        content = await file.read()
        await file.seek(0)
        
        if provider == "s3":
            return StorageUploadResult(url=await cls._upload_to_s3(content, filename))
        elif provider == "azure":
            return StorageUploadResult(url=await cls._upload_to_azure(content, filename))
        elif provider == "cloudinary":
            return await cls._upload_to_cloudinary(content, filename)
        else:
            # Fallback to local file storage
            from app.utils.file_utils import save_upload_file
            from starlette.concurrency import run_in_threadpool
            
            saved_path = await run_in_threadpool(save_upload_file, upload_dir, file)
            base_url = (settings.upload_base_url or "").rstrip("/")
            filename = Path(saved_path).name
            if base_url:
                if not base_url.endswith("/media"):
                    return StorageUploadResult(url=f"{base_url}/media/{filename}")
                else:
                    return StorageUploadResult(url=f"{base_url}/{filename}")
            else:
                return StorageUploadResult(url=f"/media/{filename}")

    @classmethod
    async def delete_file(cls, file_url: str, public_id: str | None = None) -> None:
        provider = cls.get_provider()
        if not file_url:
            return
            
        if provider == "s3":
            await cls._delete_from_s3(file_url)
        elif provider == "azure":
            await cls._delete_from_azure(file_url)
        elif provider == "cloudinary":
            await cls._delete_from_cloudinary(public_id)
        else:
            # Local delete
            filename = file_url.split("/")[-1]
            local_path = Path(settings.upload_dir) / filename
            if local_path.exists():
                try:
                    os.remove(local_path)
                except OSError as e:
                    logger.error(f"Failed to delete local file {local_path}: {e}")

    @classmethod
    async def _upload_to_cloudinary(
        cls, content: bytes, filename: str
    ) -> StorageUploadResult:
        try:
            import cloudinary
            import cloudinary.uploader
        except ImportError as exc:
            raise RuntimeError(
                "cloudinary is required for Cloudinary storage. "
                "Install it using 'pip install cloudinary'"
            ) from exc

        if not all(
            (
                settings.cloudinary_cloud_name,
                settings.cloudinary_api_key,
                settings.cloudinary_api_secret,
            )
        ):
            raise RuntimeError(
                "CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY and "
                "CLOUDINARY_API_SECRET are required for Cloudinary storage"
            )

        cloudinary.config(
            cloud_name=settings.cloudinary_cloud_name,
            api_key=settings.cloudinary_api_key,
            api_secret=settings.cloudinary_api_secret,
            secure=True,
        )

        import io

        upload_options = {
            "resource_type": "image",
            "folder": settings.cloudinary_folder,
            "use_filename": False,
            "unique_filename": True,
            "overwrite": False,
            "transformation": cls._cloudinary_transformations(),
        }
        result = await run_in_threadpool(
            cloudinary.uploader.upload,
            io.BytesIO(content),
            **upload_options,
        )
        secure_url = result.get("secure_url") or result.get("url")
        public_id = result.get("public_id")
        if not secure_url or not public_id:
            raise RuntimeError("Cloudinary returned an incomplete upload response")

        delivery_url = cloudinary.CloudinaryImage(public_id).build_url(
            secure=True,
            transformation=cls._cloudinary_transformations(),
        )
        return StorageUploadResult(url=delivery_url or secure_url, public_id=public_id)

    @classmethod
    async def _delete_from_cloudinary(cls, public_id: str | None) -> None:
        if not public_id:
            logger.warning("Cannot delete Cloudinary avatar without a public_id")
            return

        try:
            import cloudinary
            import cloudinary.uploader
        except ImportError:
            logger.error("cloudinary is required to delete Cloudinary assets")
            return

        if not all(
            (
                settings.cloudinary_cloud_name,
                settings.cloudinary_api_key,
                settings.cloudinary_api_secret,
            )
        ):
            logger.error("Cloudinary credentials are missing; asset was not deleted")
            return

        cloudinary.config(
            cloud_name=settings.cloudinary_cloud_name,
            api_key=settings.cloudinary_api_key,
            api_secret=settings.cloudinary_api_secret,
            secure=True,
        )
        try:
            await run_in_threadpool(
                cloudinary.uploader.destroy,
                public_id,
                resource_type="image",
                invalidate=True,
            )
        except Exception as exc:
            logger.error("Failed to delete Cloudinary asset %s: %s", public_id, exc)

    @classmethod
    async def _upload_to_s3(cls, content: bytes, filename: str) -> str:
        try:
            import boto3
        except ImportError:
            raise RuntimeError("boto3 is required for S3 storage. Install it using 'pip install boto3'")
            
        file_extension = Path(filename).suffix or ".png"
        unique_name = f"{uuid.uuid4().hex}{file_extension}"
        
        s3_client = boto3.client(
            "s3",
            aws_access_key_id=settings.s3_access_key,
            aws_secret_access_key=settings.s3_secret_key,
            region_name=settings.s3_region or None,
            endpoint_url=settings.s3_endpoint or None,
        )
        
        import io
        s3_client.upload_fileobj(
            io.BytesIO(content),
            settings.s3_bucket,
            unique_name,
            ExtraArgs={"ContentType": cls._guess_mime_type(filename)}
        )
        
        if settings.s3_endpoint:
            return f"{settings.s3_endpoint.rstrip('/')}/{settings.s3_bucket}/{unique_name}"
        return f"https://{settings.s3_bucket}.s3.amazonaws.com/{unique_name}"

    @classmethod
    async def _delete_from_s3(cls, file_url: str) -> None:
        try:
            import boto3
        except ImportError:
            return
        filename = file_url.split("/")[-1]
        s3_client = boto3.client(
            "s3",
            aws_access_key_id=settings.s3_access_key,
            aws_secret_access_key=settings.s3_secret_key,
            region_name=settings.s3_region or None,
            endpoint_url=settings.s3_endpoint or None,
        )
        try:
            s3_client.delete_object(Bucket=settings.s3_bucket, Key=filename)
        except Exception as e:
            logger.error(f"Failed to delete {filename} from S3: {e}")

    @classmethod
    async def _upload_to_azure(cls, content: bytes, filename: str) -> str:
        try:
            from azure.storage.blob import BlobServiceClient, ContentSettings
        except ImportError:
            raise RuntimeError("azure-storage-blob is required for Azure storage. Install it using 'pip install azure-storage-blob'")
            
        file_extension = Path(filename).suffix or ".png"
        unique_name = f"{uuid.uuid4().hex}{file_extension}"
        
        blob_service_client = BlobServiceClient.from_connection_string(settings.azure_connection_string)
        blob_client = blob_service_client.get_blob_client(container=settings.azure_container, blob=unique_name)
        
        content_settings = ContentSettings(content_type=cls._guess_mime_type(filename))
        blob_client.upload_blob(content, content_settings=content_settings)
        
        return blob_client.url

    @classmethod
    async def _delete_from_azure(cls, file_url: str) -> None:
        try:
            from azure.storage.blob import BlobServiceClient
        except ImportError:
            return
        filename = file_url.split("/")[-1]
        blob_service_client = BlobServiceClient.from_connection_string(settings.azure_connection_string)
        blob_client = blob_service_client.get_blob_client(container=settings.azure_container, blob=filename)
        try:
            blob_client.delete_blob()
        except Exception as e:
            logger.error(f"Failed to delete {filename} from Azure: {e}")

    @staticmethod
    def _guess_mime_type(filename: str) -> str:
        ext = Path(filename).suffix.lower()
        if ext in (".jpg", ".jpeg"):
            return "image/jpeg"
        elif ext == ".png":
            return "image/png"
        elif ext == ".gif":
            return "image/gif"
        elif ext == ".webp":
            return "image/webp"
        return "application/octet-stream"
