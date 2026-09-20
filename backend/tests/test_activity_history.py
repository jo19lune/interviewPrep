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

from app.data.database import get_db
from app.main import app
from app.models.base import Base
from app.models.user import User
from app.services.auth_service import hash_password


TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture
async def activity_client(monkeypatch):
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

    async with session_factory() as session:
        user = User(
            courriel="owner@example.com",
            mot_de_passe_hash=hash_password("SecurePassword123!"),
            est_actif=True,
        )
        session.add(user)
        await session.commit()

    app.dependency_overrides[get_db] = override_get_db

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://testserver",
    ) as client:
        yield client, session_factory

    app.dependency_overrides.clear()
    await engine.dispose()


@pytest.mark.asyncio
async def test_activity_history_crud_for_current_user(activity_client):
    client, session_factory = activity_client
    register = await client.post(
        "/api/v1/auth/register",
        json={
            "courriel": "user@example.com",
            "mot_de_passe": "SecurePassword123!",
        },
    )
    assert register.status_code == 201
    token = register.json()["access_token"]

    create = await client.post(
        "/api/v1/activities",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "type": "session",
            "message": "Simulation démarrée",
            "metadata": {"exercise_id": "abc"},
        },
    )
    assert create.status_code == 201
    body = create.json()
    assert body["message"] == "Simulation démarrée"
    assert body["type"] == "session"

    list_resp = await client.get(
        "/api/v1/activities",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 1

    detail = await client.get(
        f"/api/v1/activities/{body['id']}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert detail.status_code == 200
    assert detail.json()["message"] == "Simulation démarrée"

    update = await client.put(
        f"/api/v1/activities/{body['id']}",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "message": "Simulation terminée",
            "metadata": {"exercise_id": "xyz", "score": 80},
        },
    )
    assert update.status_code == 200
    assert update.json()["message"] == "Simulation terminée"

    delete = await client.delete(
        f"/api/v1/activities/{body['id']}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert delete.status_code == 204

    get_after_delete = await client.get(
        f"/api/v1/activities/{body['id']}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert get_after_delete.status_code == 404


@pytest.mark.asyncio
async def test_activity_history_isolated_by_user(activity_client):
    client, _ = activity_client

    user1 = await client.post(
        "/api/v1/auth/register",
        json={
            "courriel": "alice@example.com",
            "mot_de_passe": "SecurePassword123!",
        },
    )
    user2 = await client.post(
        "/api/v1/auth/register",
        json={
            "courriel": "bob@example.com",
            "mot_de_passe": "SecurePassword123!",
        },
    )
    assert user1.status_code == 201
    assert user2.status_code == 201

    activity = await client.post(
        "/api/v1/activities",
        headers={"Authorization": f"Bearer {user1.json()['access_token']}"},
        json={
            "type": "exercise",
            "message": "Premier exercice validé",
        },
    )
    assert activity.status_code == 201
    activity_id = activity.json()["id"]

    forbidden = await client.get(
        f"/api/v1/activities/{activity_id}",
        headers={"Authorization": f"Bearer {user2.json()['access_token']}"},
    )
    assert forbidden.status_code == 404
