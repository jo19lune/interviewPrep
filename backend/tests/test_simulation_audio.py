"""Tests du contrat de l'endpoint de réponse audio des simulations.

Contrat attendu : `POST /api/v1/simulation/answer/audio?session_id=<uuid>` avec
le fichier audio en body multipart (`audio`). `session_id` est un paramètre de
requête (et non un champ du formulaire) conformément à la signature FastAPI
`session_id: UUID` sans `Form(...)`.
"""

import os
import sys

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("SECRET_KEY", "test-secret-key")
os.environ.setdefault("ACCESS_TOKEN_EXPIRE_MINUTES", "30")
os.environ.setdefault("REFRESH_TOKEN_EXPIRE_MINUTES", "60")
os.environ.setdefault("OPENAI_API_KEY", "test-key")
os.environ.setdefault("AI_PRIMARY_MODEL", "gpt-4o-mini")
os.environ.setdefault("AI_FALLBACK_MODEL", "gpt-4o-mini")
os.environ.setdefault("UPLOAD_BASE_URL", "http://localhost:8000/media")

from app.config.settings import settings
from app.data.database import get_db
from app.main import app
from app.models.base import Base

TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

VALID_SESSION_ID = "12345678-1234-5678-1234-567812345678"


@pytest.fixture
async def audio_client(monkeypatch):
    """Client authentifié avec la transcription audio désactivée afin que la
    requête s'arrête à la logique métier (503) sans appeler le fournisseur IA."""
    monkeypatch.setattr(settings, "ai_feature_transcribe_audio", False)

    engine = create_async_engine(
        TEST_DATABASE_URL,
        poolclass=StaticPool,
        connect_args={"check_same_thread": False},
    )
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)

    session_factory = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )

    async def override_get_db():
        async with session_factory() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://testserver",
    ) as client:
        register = await client.post(
            "/api/v1/auth/register",
            json={
                "courriel": "audio@example.com",
                "mot_de_passe": "SecurePassword123!",
            },
        )
        assert register.status_code == 201
        token = register.json()["access_token"]
        yield client, {"Authorization": f"Bearer {token}"}

    app.dependency_overrides.clear()
    await engine.dispose()


@pytest.mark.asyncio
async def test_audio_answer_requires_session_id_as_query_param(audio_client):
    """Le `session_id` dans le body multipart ne suffit pas : sans le query
    parameter, FastAPI répond 422. (C'était le bug côté client Flutter.)"""
    client, headers = audio_client
    resp = await client.post(
        "/api/v1/simulation/answer/audio",
        headers=headers,
        files={
            "audio": ("reponse.m4a", b"fake-audio-bytes", "audio/m4a"),
        },
    )
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_audio_answer_contract_with_query_session_id(audio_client):
    """Avec `session_id` en query parameter et un fichier audio valide, la
    requête passe la validation et atteint la logique métier (503 car la
    transcription est désactivée dans ce test)."""
    client, headers = audio_client
    resp = await client.post(
        "/api/v1/simulation/answer/audio",
        headers=headers,
        params={"session_id": VALID_SESSION_ID},
        files={
            "audio": ("reponse.m4a", b"fake-audio-bytes", "audio/m4a"),
        },
    )
    assert resp.status_code == 503
    assert "transcription" in resp.json()["detail"].lower()


@pytest.mark.asyncio
async def test_audio_answer_rejects_non_audio_file(audio_client):
    """Un fichier dont le type MIME n'est pas audio/ est rejeté (400)."""
    client, headers = audio_client
    resp = await client.post(
        "/api/v1/simulation/answer/audio",
        headers=headers,
        params={"session_id": VALID_SESSION_ID},
        files={
            "audio": ("doc.txt", b"not-audio", "text/plain"),
        },
    )
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_audio_answer_requires_auth(audio_client):
    """L'endpoint est protégé : sans token Bearer, réponse 401."""
    client, _ = audio_client
    resp = await client.post(
        "/api/v1/simulation/answer/audio",
        params={"session_id": VALID_SESSION_ID},
        files={
            "audio": ("reponse.m4a", b"fake-audio-bytes", "audio/m4a"),
        },
    )
    assert resp.status_code == 401