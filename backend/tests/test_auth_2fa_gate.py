"""Vérifie que la 2FA par email s'applique à la fois au login par mot de passe
et à la connexion Google, pour éviter un contournement du second factor."""
import sys
import types
from datetime import datetime, timezone
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch
from uuid import UUID

import pytest
from fastapi import BackgroundTasks

from app.routers import auth as auth_router
from app.services.auth_tokens import TokenResponse

_USER_ID = UUID("11111111-2222-3333-4444-555555555555")
_USER_EMAIL = "user@example.com"
_VALID_CLAIMS = {
    "iss": "https://accounts.google.com",
    "email": _USER_EMAIL,
    "email_verified": True,
}


def _user() -> SimpleNamespace:
    return SimpleNamespace(
        id=_USER_ID,
        courriel=_USER_EMAIL,
        prenom="Jean",
        nom="Dupont",
        domaine=None,
        niveau=None,
        est_actif=True,
        avatar_url=None,
        cree_le=datetime.now(timezone.utc),
    )


def _tokens() -> TokenResponse:
    return TokenResponse(access_token="at", refresh_token="rt")


@pytest.fixture
def stub_google_sdk():
    """`google-auth` n'est pas une dépendance de test : on injecte un module
    minimal pour isoler la logique de 2FA de la vérification de signature."""
    id_token_module = types.ModuleType("google.oauth2.id_token")
    id_token_module.verify_oauth2_token = lambda *args, **kwargs: dict(_VALID_CLAIMS)

    transport = types.ModuleType("google.auth.transport.requests")
    transport.Request = object

    oauth2 = types.ModuleType("google.oauth2")
    oauth2.id_token = id_token_module
    auth_pkg = types.ModuleType("google.auth")
    auth_pkg.transport = types.ModuleType("google.auth.transport")
    auth_pkg.transport.requests = transport
    google_pkg = types.ModuleType("google")
    google_pkg.auth = auth_pkg
    google_pkg.oauth2 = oauth2

    injected = {
        name: module
        for name, module in {
            "google": google_pkg,
            "google.auth": auth_pkg,
            "google.auth.transport": auth_pkg.transport,
            "google.auth.transport.requests": transport,
            "google.oauth2": oauth2,
            "google.oauth2.id_token": id_token_module,
        }.items()
    }
    saved = {name: sys.modules.get(name) for name in injected}
    sys.modules.update(injected)
    try:
        yield
    finally:
        for name, module in saved.items():
            if module is None:
                sys.modules.pop(name, None)
            else:
                sys.modules[name] = module


@pytest.mark.asyncio
async def test_google_login_requires_otp_when_2fa_enabled(stub_google_sdk):
    with (
        patch.object(auth_router.settings, "email_2fa_enabled", True),
        patch.object(auth_router.settings, "email_2fa_otp_ttl_minutes", 10),
        patch.object(
            auth_router,
            "authenticate_google_user",
            AsyncMock(return_value=(_user(), _tokens())),
        ),
        patch.object(auth_router, "issue_otp", AsyncMock()) as issue_otp,
    ):
        result = await auth_router.google_login(
            auth_router.GoogleLoginRequest(id_token="x" * 30),
            BackgroundTasks(),
            AsyncMock(),
        )

    assert result.requires_2fa is True
    assert result.challenge_expires_in_seconds == 600
    # Aucun jeton ne doit être délivré avant validation du code.
    assert result.access_token is None
    assert result.refresh_token is None
    assert result.user.courriel == _USER_EMAIL
    issue_otp.assert_awaited_once()
    assert issue_otp.await_args.args[2] == "login_2fa"


@pytest.mark.asyncio
async def test_google_login_delivers_tokens_when_2fa_disabled(stub_google_sdk):
    with (
        patch.object(auth_router.settings, "email_2fa_enabled", False),
        patch.object(
            auth_router,
            "authenticate_google_user",
            AsyncMock(return_value=(_user(), _tokens())),
        ),
        patch.object(auth_router, "issue_otp", AsyncMock()) as issue_otp,
    ):
        result = await auth_router.google_login(
            auth_router.GoogleLoginRequest(id_token="x" * 30),
            BackgroundTasks(),
            AsyncMock(),
        )

    assert result.requires_2fa is False
    assert result.access_token == "at"
    assert result.refresh_token == "rt"
    assert result.user.courriel == _USER_EMAIL
    issue_otp.assert_not_awaited()


def test_login_response_schema_accepts_2fa_payload_without_tokens():
    """Le schéma doit valider la charge utile du challenge 2FA (sans jeton)."""
    user = auth_router.UserResponse.model_validate(_user())
    payload = auth_router.LoginResponse(
        requires_2fa=True,
        challenge_expires_in_seconds=600,
        user=user,
    )

    assert payload.requires_2fa is True
    assert payload.access_token is None
    assert payload.refresh_token is None
    assert payload.token_type == "bearer"
