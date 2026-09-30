"""Contrat de `GET /health`.

Cet endpoint est le premier réflexe de diagnostic en production. Il expose la
configuration **résolue** des intégrations externes — sans jamais renvoyer de
secret — parce que les pannes observées (« email non reçu », « IA 429 »,
« avatar 500 ») étaient impossibles à distinguer d'un défaut de code sans
accès aux variables d'environnement de Render.
"""

import pytest
from httpx import ASGITransport, AsyncClient


@pytest.fixture
async def client():
    from app.main import app

    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as http_client:
        yield http_client


@pytest.mark.asyncio
async def test_health_reports_status_and_integration_configuration(client):
    response = await client.get("/health")

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"

    integrations = body["integrations"]
    assert set(integrations) == {"email", "ai", "storage", "google_sign_in"}

    assert integrations["email"]["host"]
    assert isinstance(integrations["email"]["port"], int)
    assert isinstance(integrations["email"]["configured"], bool)

    assert integrations["ai"]["provider"] == "groq"
    assert integrations["ai"]["base_url"] == "https://api.groq.com/openai/v1"
    assert integrations["ai"]["configured"] is True

    assert isinstance(integrations["storage"]["configured"], bool)

    # Le stockage local est toujours « configuré » ; Cloudinary ne l'est que si
    # les trois identifiants sont présents.
    from app.config.settings import settings

    if settings.storage_provider == "cloudinary":
        expected_storage = bool(
            settings.cloudinary_cloud_name
            and settings.cloudinary_api_key
            and settings.cloudinary_api_secret
        )
    else:
        expected_storage = True
    assert integrations["storage"]["configured"] is expected_storage


@pytest.mark.asyncio
async def test_health_never_leaks_secrets(client):
    """Aucune clé, quel que soit le fournisseur actif."""
    response = await client.get("/health")
    raw = response.text

    for secret_marker in (
        "gsk_", "sk-", "API_KEY", "SECRET", "PASSWORD",
        "cloudinary_api_secret", "SMTP_PASSWORD", "OPENAI_API_KEY",
    ):
        assert secret_marker not in raw, f"{secret_marker} exposé par /health"