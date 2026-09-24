from fastapi.testclient import TestClient

from app.config.settings import settings
from app.main import app


def test_api_route_requires_application_key_in_production(monkeypatch):
    monkeypatch.setattr(settings, "app_environment", "production")
    monkeypatch.setattr(settings, "backend_api_key", "test-application-key")

    client = TestClient(app)
    response = client.post("/api/v1/auth/register", json={})

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid application key"


def test_api_route_accepts_application_key_and_keeps_validation(monkeypatch):
    monkeypatch.setattr(settings, "app_environment", "production")
    monkeypatch.setattr(settings, "backend_api_key", "test-application-key")

    client = TestClient(app)
    response = client.post(
        "/api/v1/auth/register",
        json={},
        headers={"X-API-Key": "test-application-key"},
    )

    assert response.status_code == 422
