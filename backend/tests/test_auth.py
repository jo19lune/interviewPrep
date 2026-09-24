"""Tests unitaires pour l'authentification"""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from uuid import uuid4

from app.main import app
from app.data.database import get_db
from app.models.base import Base
from app.models.user import User
from app.services.auth_service import hash_password


# Configuration de la BD de test
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

@pytest.fixture(autouse=True)
async def test_db():
    """Créer une BD de test"""
    engine = create_async_engine(
        TEST_DATABASE_URL,
        echo=False,
        future=True,
        poolclass=StaticPool,
        connect_args={"check_same_thread": False},
    )
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    AsyncSessionLocal = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    async def override_get_db():
        async with AsyncSessionLocal() as session:
            yield session
    
    app.dependency_overrides[get_db] = override_get_db
    
    yield AsyncSessionLocal
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    
    await engine.dispose()


@pytest.fixture
def client():
    """Client de test FastAPI"""
    return TestClient(app)


def test_register_new_user(client, test_db):
    """Tester la création d'un nouveau compte"""
    response = client.post(
        "/api/v1/auth/register",
        json={
            "courriel": "test@example.com",
            "mot_de_passe": "SecurePassword123!",
            "prenom": "John",
            "nom": "Doe"
        }
    )
    
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["courriel"] == "test@example.com"


def test_register_duplicate_email(client):
    """Tester l'enregistrement avec email déjà utilisé"""
    # Première inscription
    client.post(
        "/api/v1/auth/register",
        json={
            "courriel": "test@example.com",
            "mot_de_passe": "SecurePassword123!"
        }
    )
    
    # Deuxième inscription avec même email
    response = client.post(
        "/api/v1/auth/register",
        json={
            "courriel": "test@example.com",
            "mot_de_passe": "DifferentPassword123!"
        }
    )
    
    assert response.status_code == 409


def test_login_success(client):
    """Tester une connexion réussie"""
    # S'enregistrer d'abord
    client.post(
        "/api/v1/auth/register",
        json={
            "courriel": "test@example.com",
            "mot_de_passe": "SecurePassword123!"
        }
    )
    
    # Ensuite se connecter
    response = client.post(
        "/api/v1/auth/login",
        json={
            "courriel": "test@example.com",
            "mot_de_passe": "SecurePassword123!"
        }
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data


def test_login_invalid_password(client):
    """Tester une connexion avec mauvais mot de passe"""
    # S'enregistrer d'abord
    client.post(
        "/api/v1/auth/register",
        json={
            "courriel": "test@example.com",
            "mot_de_passe": "SecurePassword123!"
        }
    )
    
    # Essayer de se connecter avec mauvais mot de passe
    response = client.post(
        "/api/v1/auth/login",
        json={
            "courriel": "test@example.com",
            "mot_de_passe": "WrongPassword!"
        }
    )
    
    assert response.status_code == 401


def test_get_profile_with_token(client):
    """Tester la récupération du profil avec un token valide"""
    # S'enregistrer et obtenir un token
    register_response = client.post(
        "/api/v1/auth/register",
        json={
            "courriel": "test@example.com",
            "mot_de_passe": "SecurePassword123!",
            "prenom": "John"
        }
    )
    token = register_response.json()["access_token"]
    
    # Récupérer le profil
    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["courriel"] == "test@example.com"
    assert data["prenom"] == "John"


def test_get_profile_without_token(client):
    """Tester la récupération du profil sans token"""
    response = client.get("/api/v1/auth/me")
    
    assert response.status_code == 401  # L'authentification échoue avec 401 Unauthorized
