"""Invariant central du correctif email : l'envoi n'est jamais détaché.

Une tâche de fond qui échoue en silence est l'origine du faux « Code envoyé ».
Ce module verrouille le fait qu'aucun chemin ne permet de créer un OTP
« believed delivered » alors que le transport a échoué.
"""

import os
import sys
from unittest.mock import AsyncMock, patch

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("SECRET_KEY", "test-secret-key")
os.environ.setdefault("ACCESS_TOKEN_EXPIRE_MINUTES", "30")
os.environ.setdefault("REFRESH_TOKEN_EXPIRE_MINUTES", "60")
os.environ.setdefault("OPENAI_API_KEY", "test-key")
os.environ.setdefault("AI_PRIMARY_MODEL", "gpt-4o-mini")
os.environ.setdefault("AI_FALLBACK_MODEL", "gpt-4o-mini")

import inspect

from app.services import otp_service
from app.services.email_service import EmailDeliveryError
from app.services.otp_service import issue_otp


class _FakeDb:
    def __init__(self):
        self.added = []
        self.executed = []
        self.commits = 0

    def add(self, obj):
        self.added.append(obj)

    async def execute(self, stmt):
        self.executed.append(stmt)

    async def commit(self):
        self.commits += 1


def test_issue_otp_has_no_background_task_escape_hatch():
    """Aucune tâche de fond ne doit rester dans l'API du service.

    C'est le garde-fou contre la régression : si `background_tasks` réapparaît
    dans la signature, un appelant peut à nouveau annoncer un envoi qu'aucun
    processus ne surveille.
    """
    signature = inspect.signature(issue_otp)

    assert "background_tasks" not in signature.parameters

    # Le symbole ne doit plus être importé non plus : un simple `add_task`
    # resterait sinon possible dans une future modification.
    assert not hasattr(otp_service, "BackgroundTasks")


@pytest.mark.asyncio
async def test_failed_delivery_invalidates_the_otp_and_raises():
    """Aucun code valide ne doit survivre à un échec de transport.

    Le cas le plus vicieux : l'OTP est en base, l'email est parti en échec.
    L'utilisateur peut alors valider un code qu'il n'a jamais reçu, et le
    compte reste verrouillé jusqu'à expiration.
    """
    db = _FakeDb()

    with patch.object(
        otp_service,
        "send_otp_email",
        AsyncMock(side_effect=EmailDeliveryError("Brevo a refusé l'envoi (HTTP 401)")),
    ):
        with pytest.raises(EmailDeliveryError):
            await issue_otp(db, "user@example.com", "login_2fa")

    # 1) consommation des OTP précédents, 2) invalidation du nouveau code.
    assert len(db.executed) == 2, "l'OTP échoué doit être invalidé en base"
    assert db.commits == 2


@pytest.mark.asyncio
async def test_successful_delivery_keeps_the_otp_usable():
    """Contre-régression : le chemin nominal doit rester inchangé."""
    db = _FakeDb()

    with patch.object(otp_service, "send_otp_email", AsyncMock(return_value=None)):
        code = await issue_otp(db, "user@example.com", "login_2fa")

    assert len(code) == 6 and code.isdigit()
    assert len(db.executed) == 1, "pas d'invalidation quand l'envoi réussit"
