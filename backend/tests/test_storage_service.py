import sys
import types

import pytest

from app.config.settings import settings
from app.services.storage_service import StorageService


@pytest.mark.asyncio
async def test_cloudinary_upload_returns_secure_url_without_duplicate_transformation(monkeypatch):
    calls = {}

    def config(**kwargs):
        calls["config"] = kwargs

    secure_url = (
        "https://res.cloudinary.com/demo/image/upload/"
        "c_fill,g_auto,h_512,w_512,q_auto,f_webp/v1700000000/"
        "interviewprep/avatars/avatar-id.webp"
    )

    def upload(file, **kwargs):
        calls["upload"] = kwargs
        assert file.read() == b"image-content"
        return {
            "secure_url": secure_url,
            "public_id": "interviewprep/avatars/avatar-id",
        }

    cloudinary_module = types.ModuleType("cloudinary")
    cloudinary_module.config = config
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

    # Le secure_url renvoyé par l'upload inclut déjà la transformation :
    # il est retourné tel quel, sans reconstruction build_url (double application).
    assert result.url == secure_url
    assert result.public_id == "interviewprep/avatars/avatar-id"
    assert calls["config"]["secure"] is True
    assert calls["upload"]["folder"] == "interviewprep/avatars"
    assert calls["upload"]["transformation"][1] == {
        "quality": "auto",
        "fetch_format": "webp",
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


@pytest.mark.asyncio
async def test_cloudinary_delete_falls_back_to_url_extraction(monkeypatch):
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
    monkeypatch.setattr(settings, "storage_provider", "cloudinary")

    # public_id perdu (avatar créé avant l'ajout de la colonne) : extraction
    # best-effort depuis l'URL de livraison, transformation et version ignorées.
    url = (
        "https://res.cloudinary.com/demo/image/upload/"
        "c_fill,g_auto,h_512,w_512,q_auto,f_webp/v1700000000/"
        "interviewprep/avatars/avatar-id.webp"
    )
    await StorageService.delete_file(url, public_id=None)

    assert calls["destroy"] == (
        "interviewprep/avatars/avatar-id",
        {"resource_type": "image", "invalidate": True},
    )


@pytest.mark.asyncio
async def test_extract_public_id_from_url_returns_none_on_non_cloudinary_url():
    assert StorageService._extract_public_id_from_url(None) is None
    assert StorageService._extract_public_id_from_url("") is None
    assert (
        StorageService._extract_public_id_from_url(
            "https://cdn.example.com/media/avatar.png"
        )
        is None
    )
