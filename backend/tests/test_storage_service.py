import sys
import types

import pytest

from app.config.settings import settings
from app.services.storage_service import StorageService


@pytest.mark.asyncio
async def test_cloudinary_upload_uses_automatic_format_transformation(monkeypatch):
    calls = {}

    def config(**kwargs):
        calls["config"] = kwargs

    def upload(file, **kwargs):
        calls["upload"] = kwargs
        assert file.read() == b"image-content"
        return {
            "secure_url": "https://res.cloudinary.com/demo/image/upload/avatar.webp",
            "public_id": "interviewprep/avatars/avatar-id",
        }

    cloudinary_module = types.ModuleType("cloudinary")
    cloudinary_module.config = config
    cloudinary_module.CloudinaryImage = lambda public_id: types.SimpleNamespace(
        build_url=lambda **kwargs: (
            "https://res.cloudinary.com/demo/image/upload/"
            "c_fill,g_auto,h_512,w_512,q_auto,f_auto/avatar.webp"
        )
    )
    uploader_module = types.ModuleType("cloudinary.uploader")
    uploader_module.upload = upload
    cloudinary_module.uploader = uploader_module
    monkeypatch.setitem(sys.modules, "cloudinary", cloudinary_module)
    monkeypatch.setitem(sys.modules, "cloudinary.uploader", uploader_module)

    monkeypatch.setattr(settings, "cloudinary_cloud_name", "demo")
    monkeypatch.setattr(settings, "cloudinary_api_key", "key")
    monkeypatch.setattr(settings, "cloudinary_api_secret", "secret")
    monkeypatch.setattr(settings, "cloudinary_folder", "interviewprep/avatars")

    result = await StorageService._upload_to_cloudinary(
        b"image-content", "avatar.png"
    )

    assert result.url.endswith("q_auto,f_auto/avatar.webp")
    assert result.public_id == "interviewprep/avatars/avatar-id"
    assert calls["config"]["secure"] is True
    assert calls["upload"]["folder"] == "interviewprep/avatars"
    assert calls["upload"]["transformation"][1] == {
        "quality": "auto",
        "fetch_format": "auto",
    }


@pytest.mark.asyncio
async def test_cloudinary_delete_uses_public_id(monkeypatch):
    calls = {}

    def config(**kwargs):
        calls["config"] = kwargs

    def destroy(public_id, **kwargs):
        calls["destroy"] = (public_id, kwargs)
        return {"result": "ok"}

    cloudinary_module = types.ModuleType("cloudinary")
    cloudinary_module.config = config
    uploader_module = types.ModuleType("cloudinary.uploader")
    uploader_module.destroy = destroy
    cloudinary_module.uploader = uploader_module
    monkeypatch.setitem(sys.modules, "cloudinary", cloudinary_module)
    monkeypatch.setitem(sys.modules, "cloudinary.uploader", uploader_module)

    monkeypatch.setattr(settings, "cloudinary_cloud_name", "demo")
    monkeypatch.setattr(settings, "cloudinary_api_key", "key")
    monkeypatch.setattr(settings, "cloudinary_api_secret", "secret")

    await StorageService._delete_from_cloudinary("interviewprep/avatars/avatar-id")

    assert calls["destroy"] == (
        "interviewprep/avatars/avatar-id",
        {"resource_type": "image", "invalidate": True},
    )
