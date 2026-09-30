"""Contrat HTTP de `POST /auth/forgot-password`.

Régression centrale : la route renvoyait 200 « Code de reinitialisation
envoye » alors que les trois tentatives SMTP avaient échoué, parce que
l'envoi était planifié en `BackgroundTasks` et que ses erreurs étaient
avalées. Le client affichait donc « Code envoyé » sans qu'aucun email ne soit
jamais parti.
"""

from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

import pytest
from fastapi import HTTPException

from app.routers import password_reset as reset_router
from app.schemas.auth import ForgotPasswordRequest
from app.services.email_service import EmailDeliveryError

_EMAIL = "user@example.com"


def _request() -> SimpleNamespace:
    return SimpleNamespace(client=SimpleNamespace(host="203.0.113.9"))


def _response(payload) -> dict:
    return payload


@pytest.mark.asyncio
async def test_success_path_returns_200_with_expiry():
    with (
        patch.object(reset_router, "check_rate_limit"),
        patch.object(reset_router, "clear_attempts"),
        patch.object(
            reset_router,
            "send_password_reset_code_if_user_exists",
            AsyncMock(return_value={"sent": True, "expires_in_minutes": 30}),
        ),
    ):
        result = await reset_router.forgot_password(
            ForgotPasswordRequest(courriel=_EMAIL), _request(), AsyncMock()
        )

    assert "envoye" in result["message"]
    assert result["expires_in_minutes"] == 30


@pytest.mark.asyncio
async def test_unknown_account_returns_generic_200_without_leaking():
    """Anti-énumération préservée : un compte inexistant ne renvoie pas 503."""
    with (
        patch.object(reset_router, "check_rate_limit"),
        patch.object(reset_router, "record_failed_attempt"),
        patch.object(reset_router.asyncio, "sleep", AsyncMock()),
        patch.object(
            reset_router,
            "send_password_reset_code_if_user_exists",
            AsyncMock(return_value={"sent": False}),
        ),
    ):
        result = await reset_router.forgot_password(
            ForgotPasswordRequest(courriel=_EMAIL), _request(), AsyncMock()
        )

    assert result == {
        "message": "Si ce compte existe, un code de reinitialisation a ete envoye."
    }
    assert "expires_in_minutes" not in result


@pytest.mark.asyncio
async def test_delivery_failure_returns_503_instead_of_false_success():
    """Le cœur de la correction : plus de 200 quand aucun email n'est parti."""
    with (
        patch.object(reset_router, "check_rate_limit"),
        patch.object(reset_router, "record_failed_attempt"),
        patch.object(
            reset_router,
            "send_password_reset_code_if_user_exists",
            AsyncMock(side_effect=EmailDeliveryError("SMTP 535")),
        ),
    ):
        with pytest.raises(HTTPException) as excinfo:
            await reset_router.forgot_password(
                ForgotPasswordRequest(courriel=_EMAIL), _request(), AsyncMock()
            )

    exc = excinfo.value
    assert exc.status_code == 503
    assert exc.headers["Retry-After"] == "60"
    # Le message doit être explicite sur l'absence d'envoi.
    assert "Aucun code" in exc.detail


@pytest.mark.asyncio
async def test_route_no_longer_accepts_background_tasks():
    """Signature : plus de BackgroundTasks.

    Une tâche de fond ne peut pas signaler son échec au client ; la présence du
    paramètre permettrait de reintroduire silencieusement le défaut corrigé.
    """
    import inspect

    params = inspect.signature(reset_router.forgot_password).parameters
    assert "background_tasks" not in params
