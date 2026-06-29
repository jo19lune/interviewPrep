import os
import uuid
import logging
from pathlib import Path
from fastapi import UploadFile
from app.config.settings import settings

logger = logging.getLogger(__name__)


class StorageService:
    @staticmethod
    def get_provider() -> str:
        return settings.storage_provider.lower()

    @classmethod
    async def upload_file(cls, file: UploadFile, upload_dir: str) -> str:
        provider = cls.get_provider()
        filename = file.filename or "avatar.png"
        
        # Read file contents for remote storage or validation
        content = await file.read()
        await file.seek(0)
        
        if provider == "s3":
            return await cls._upload_to_s3(content, filename)
        elif provider == "azure":
            return await cls._upload_to_azure(content, filename)
        else:
            # Fallback to local file storage
            from app.utils.file_utils import save_upload_file
            from starlette.concurrency import run_in_threadpool
            
            saved_path = await run_in_threadpool(save_upload_file, upload_dir, file)
            base_url = (settings.upload_base_url or "").rstrip("/")
            filename = Path(saved_path).name
            if base_url:
                if not base_url.endswith("/media"):
                    return f"{base_url}/media/{filename}"
                else:
                    return f"{base_url}/{filename}"
            else:
                return f"/media/{filename}"

    @classmethod
    async def delete_file(cls, file_url: str) -> None:
        provider = cls.get_provider()
        if not file_url:
            return
            
        if provider == "s3":
            await cls._delete_from_s3(file_url)
        elif provider == "azure":
            await cls._delete_from_azure(file_url)
        else:
            # Local delete
            filename = file_url.split("/")[-1]
            local_path = Path(settings.upload_dir) / filename
            if local_path.exists():
                try:
                    os.remove(local_path)
                except Exception as e:
                    logger.error(f"Failed to delete local file {local_path}: {e}")

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
