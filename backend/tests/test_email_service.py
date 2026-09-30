"""Tests du service d'email.

Cible la régression principale : `email_service._send` ne doit **jamais**
signaler un succès quand la livraison a échoué. C'était la cause du message
« Code envoyé » affiché alors que les 3 tentatives SMTP avaient échoué.
"""

import sys
import types

import httpx
import pytest

from app.config.settings import settings
from app.services import email_service
from app.services.email_service import (
    EmailDeliveryError,
    EmailNotConfiguredError,
    send_otp_email,
)


def _configure(monkeypatch, **overrides):
    """Fixe un jeu d'identifiants email déterministe pour le test."""
    defaults = {
        "default_from_email": "no-reply@interviewprep.test",
        "email_provider": "brevo",
        "brevo_api_key": "xkeysib-test",
        "email_username": "",
        "email_password": "",
    }
    defaults.update(overrides)
    for key, value in defaults.items():
        monkeypatch.setattr(settings, key, value)


class _RecordingClient:
    """Double de httpx.AsyncClient capturant les appels et renvoyant une
    réponse préprogrammée."""

    def __init__(self, status_code=201, json_body=None, raises=None):
        self._status_code = status_code
        self._json_body = json_body if json_body is not None else {"messageID": "<x@y>"}
        self._raises = raises
        self.calls = []

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc_info):
        return False

    async def post(self, url, json=None, headers=None):
        self.calls.append({"url": url, "json": json, "headers": headers})
        if self._raises is not None:
            raise self._raises
        return httpx.Response(
            self._status_code,
            json=self._json_body,
            request=httpx.Request("POST", url),
        )


def _install_client(monkeypatch, client):
    monkeypatch.setattr(httpx, "AsyncClient", lambda **kwargs: client)
    return client


@pytest.mark.asyncio
async def test_brevo_send_succeeds_and_carries_api_key(monkeypatch):
    _configure(monkeypatch)
    client = _install_client(monkeypatch, _RecordingClient())

    await send_otp_email("user@example.com", "123456", "password_reset")

    assert len(client.calls) == 1
    payload = client.calls[0]["json"]
    assert client.calls[0]["headers"]["api-key"] == "xkeysib-test"
    assert payload["to"] == [{"email": "user@example.com"}]
    assert payload["subject"] == "InterviewPrep - Code de sécurité"
    # Le code doit être dans le corps textuel, sinon l'utilisateur ne reçoit rien.
    assert "123456" in payload["text"]
    assert "30 minutes" in payload["text"]


@pytest.mark.asyncio
async def test_brevo_permanent_failure_raises_without_retry(monkeypatch):
    """Un 401 (clé invalide) ne doit pas être réessayé 3 fois."""
    _configure(monkeypatch)
    client = _install_client(
        monkeypatch,
        _RecordingClient(status_code=401, json_body={"message": "Bad API key"}),
    )
    monkeypatch.setattr(email_service.asyncio, "sleep", _no_sleep)

    with pytest.raises(EmailDeliveryError) as excinfo:
        await send_otp_email("user@example.com", "123456", "password_reset")

    assert "401" in str(excinfo.value)
    assert "Bad API key" in str(excinfo.value)
    assert len(client.calls) == 1, "un échec définitif ne doit pas être réessayé"


@pytest.mark.asyncio
async def test_brevo_transient_failure_is_retried_then_raises(monkeypatch):
    """Un 500 doit être réessayé, puis remonter après épuisement des tentatives."""
    _configure(monkeypatch)
    client = _install_client(
        monkeypatch, _RecordingClient(status_code=500, json_body={"message": "oops"})
    )
    monkeypatch.setattr(email_service.asyncio, "sleep", _no_sleep)

    with pytest.raises(EmailDeliveryError) as excinfo:
        await send_otp_email("user@example.com", "123456", "password_reset")

    assert "permanently failed" in str(excinfo.value)
    assert len(client.calls) == 3


@pytest.mark.asyncio
async def test_brevo_rate_limit_is_transient(monkeypatch):
    _configure(monkeypatch)
    client = _install_client(
        monkeypatch, _RecordingClient(status_code=429, json_body={"message": "slow down"})
    )
    monkeypatch.setattr(email_service.asyncio, "sleep", _no_sleep)

    with pytest.raises(EmailDeliveryError):
        await send_otp_email("user@example.com", "123456", "password_reset")

    assert len(client.calls) == 3


@pytest.mark.asyncio
async def test_network_error_is_reported_as_delivery_error(monkeypatch):
    _configure(monkeypatch)
    client = _install_client(
        monkeypatch, _RecordingClient(raises=httpx.ConnectTimeout("boom"))
    )
    monkeypatch.setattr(email_service.asyncio, "sleep", _no_sleep)

    with pytest.raises(EmailDeliveryError):
        await send_otp_email("user@example.com", "123456", "password_reset")

    assert len(client.calls) == 3


@pytest.mark.asyncio
async def test_missing_transport_config_raises_immediately(monkeypatch):
    _configure(monkeypatch, email_provider="smtp", brevo_api_key="", email_username="", email_password="")

    with pytest.raises(EmailNotConfiguredError):
        await send_otp_email("user@example.com", "123456", "password_reset")


@pytest.mark.asyncio
async def test_auto_provider_prefers_brevo_when_key_present(monkeypatch):
    _configure(monkeypatch, email_provider="auto", brevo_api_key="xkeysib-test")
    assert settings.resolved_email_provider == "brevo"
    client = _install_client(monkeypatch, _RecordingClient())

    await send_otp_email("user@example.com", "123456", "login_2fa")

    assert len(client.calls) == 1
    assert "10 minutes" in client.calls[0]["json"]["text"]


@pytest.mark.asyncio
async def test_smtp_fallback_still_used_when_no_brevo_key(monkeypatch):
    _configure(
        monkeypatch,
        email_provider="auto",
        brevo_api_key="",
        email_username="smtp-user",
        email_password="smtp-pass",
    )
    assert settings.resolved_email_provider == "smtp"

    sent = {}

    async def fake_send(msg, **kwargs):
        sent["kwargs"] = kwargs

    monkeypatch.setattr(email_service.aiosmtplib, "send", fake_send)

    await send_otp_email("user@example.com", "123456", "password_reset")

    assert sent["kwargs"]["hostname"] == settings.email_host


@pytest.mark.asyncio
async def test_email_configured_requires_sender(monkeypatch):
    _configure(monkeypatch, default_from_email="")
    assert settings.email_configured is False


async def _no_sleep(_seconds):
    """Remplace asyncio.sleep pour que les retries n'immobilisent pas les tests."""
    return None
