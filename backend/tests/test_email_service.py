"""Tests du service d'email (transport SMTP).

Cible la régression principale : `email_service._send` ne doit **jamais**
signaler un succès quand la livraison a échoué. C'était la cause du message
« Code envoyé » affiché alors que les 3 tentatives SMTP avaient échoué.

Le second enjeu est la classification transitoire / définitif. Gmail renvoie
535 sur un mot de passe d'application invalide et 421/450/451 en cas de
débit ou d'indisponibilité : traiter le 535 comme transitoire coûterait trois
tentatives et ~14 s pour un échec certain.
"""

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
        "email_username": "no-reply@interviewprep.test",
        "email_password": "app-password-test",
        "email_host": "smtp.gmail.com",
        "email_port": 587,
        "email_use_tls": True,
        "email_use_ssl": False,
    }
    defaults.update(overrides)
    for key, value in defaults.items():
        monkeypatch.setattr(settings, key, value)


def _install_smtp(monkeypatch, exc=None):
    """Double d'`aiosmtplib.send` comptant les appels.

    Retourne le dict d'appels, ce qui permet d'affirmer « un échec définitif
    ne doit pas être réessayé » — l'assertion la plus importante du fichier.
    """
    calls = []

    async def fake_send(msg, **kwargs):
        calls.append({"msg": msg, **kwargs})
        if exc is not None:
            raise exc

    monkeypatch.setattr(email_service.aiosmtplib, "send", fake_send)
    return calls


async def _no_sleep(_seconds):
    """Remplace asyncio.sleep pour que les retries n'immobilisent pas les tests."""
    return None


# --------------------------------------------------------------------------
# Chemin nominal
# --------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_smtp_send_uses_star_tls_on_587(monkeypatch):
    _configure(monkeypatch)
    calls = _install_smtp(monkeypatch)

    await send_otp_email("user@example.com", "123456", "password_reset")

    assert len(calls) == 1
    assert calls[0]["hostname"] == "smtp.gmail.com"
    assert calls[0]["port"] == 587
    # STARTTLS sur 587 ; `use_tls` (SSL direct) est réservé au port 465.
    assert calls[0]["start_tls"] is True
    assert calls[0]["use_tls"] is False


@pytest.mark.asyncio
async def test_otp_code_and_ttl_are_present_in_the_message(monkeypatch):
    """Le code doit figurer dans le corps, sinon l'utilisateur ne reçoit rien.

    C'est l'assertion de contenu la plus importante du fichier : elle échouerait
    si l'en-tête `Subject` ou le corps textuel perdaient le code lors d'un
    refactor du `EmailMessage`.
    """
    _configure(monkeypatch)
    calls = _install_smtp(monkeypatch)

    await send_otp_email("user@example.com", "123456", "password_reset")

    msg = calls[0]["msg"]
    body = msg.get_content()
    assert "123456" in body
    # Le TTL affiché doit correspondre au TTL réellement appliqué en base.
    assert f"{settings.password_reset_code_ttl_minutes} minutes" in body
    assert msg["Subject"] == "InterviewPrep - Code de sécurité"
    assert msg["To"] == "user@example.com"


@pytest.mark.asyncio
async def test_otp_ttl_depends_on_purpose(monkeypatch):
    """Un OTP de connexion (10 min) et un code de réinitialisation (30 min)
    n'ont pas la même durée de vie ; le mail doit l'annoncer."""
    _configure(monkeypatch)
    calls = _install_smtp(monkeypatch)

    await send_otp_email("user@example.com", "123456", "login_2fa")

    assert f"{settings.email_otp_ttl_minutes} minutes" in calls[0]["msg"].get_content()


# --------------------------------------------------------------------------
# Classification des échecs
# --------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_authentication_failure_is_not_retried(monkeypatch):
    """535 (mot de passe d'application invalide) ne se répare pas en réessayant.

    Google exige un mot de passe d'application à 16 caractères ; un mot de
    passe de compte produit ce 535. Trois tentatives coûteraient ~14 s pour un
    échec certain.
    """
    _configure(monkeypatch)
    calls = _install_smtp(
        monkeypatch,
        email_service.aiosmtplib.SMTPResponseException(
            535, b"5.7.8 Username and Password not accepted"
        ),
    )
    monkeypatch.setattr(email_service.asyncio, "sleep", _no_sleep)

    with pytest.raises(EmailDeliveryError) as excinfo:
        await send_otp_email("user@example.com", "123456", "password_reset")

    assert len(calls) == 1, "un rejet d'authentification ne doit pas être réessayé"
    assert "smtp.gmail.com:587" in str(excinfo.value), (
        "le message doit nommer le serveur, seul moyen de diagnostiquer "
        "depuis les logs de déploiement"
    )


@pytest.mark.asyncio
async def test_temporary_failure_is_retried_then_raises(monkeypatch):
    """451 (trop de connexions) doit être réessayé puis remonter après épuisement."""
    _configure(monkeypatch)
    calls = _install_smtp(
        monkeypatch,
        email_service.aiosmtplib.SMTPResponseException(451, b"4.7.1 try later"),
    )
    monkeypatch.setattr(email_service.asyncio, "sleep", _no_sleep)

    with pytest.raises(EmailDeliveryError) as excinfo:
        await send_otp_email("user@example.com", "123456", "password_reset")

    assert "permanently failed" in str(excinfo.value)
    assert len(calls) == 3


@pytest.mark.asyncio
async def test_rate_limit_is_treated_as_transient(monkeypatch):
    """450 (débit Gmail dépassé) est transitoire : c'est un 4xx."""
    _configure(monkeypatch)
    calls = _install_smtp(
        monkeypatch,
        email_service.aiosmtplib.SMTPResponseException(450, b"4.7.1 exceeded quota"),
    )
    monkeypatch.setattr(email_service.asyncio, "sleep", _no_sleep)

    with pytest.raises(EmailDeliveryError):
        await send_otp_email("user@example.com", "123456", "password_reset")

    assert len(calls) == 3


def test_transient_error_container_is_a_tuple_not_a_set():
    """`isinstance()` refuse un set en second argument.

    Ce n'est pas une question de style : avec un set, `_is_transient_smtp_error`
    levait TypeError sur *toute* erreur non-`SMTPResponseException` (connexion
    refusée, port bloqué, DNS). Le TypeError était avalé en « erreur
    inattendue », donc sans retry et avec la cause réelle perdue dans les logs.
    """
    container = email_service._TRANSIENT_SMTP_ERRORS

    assert isinstance(container, tuple), (
        "un set ferait échouer isinstance() et casserait la classification"
    )
    # Sanity check : le conteneur doit être directement utilisable par isinstance.
    assert isinstance(ConnectionResetError(), container)


@pytest.mark.asyncio
async def test_connection_error_is_retried_then_raises(monkeypatch):
    """Un timeout réseau est transitoire, mais doit malgré tout finir en erreur.

    C'est le scénario du port bloqué par un hébergeur : sans_ports ouverts,
    l'utilisateur reçoit un 503 plutôt qu'un « Code envoyé ».
    """
    _configure(monkeypatch)
    calls = _install_smtp(monkeypatch, email_service.aiosmtplib.SMTPConnectError("timed out"))
    monkeypatch.setattr(email_service.asyncio, "sleep", _no_sleep)

    with pytest.raises(EmailDeliveryError):
        await send_otp_email("user@example.com", "123456", "password_reset")

    assert len(calls) == 3


@pytest.mark.asyncio
async def test_partial_success_then_failure_is_reported(monkeypatch):
    """Un 2e essai qui réussit doit stopsse le retry et ne pas lever.

    Sans ce test, une implémentation qui lève après une réussite partielle
    ferait échouer des réinitialisations qui fonctionnaient.
    """
    _configure(monkeypatch)

    responses = [
        email_service.aiosmtplib.SMTPResponseException(421, b"4.7.0 try later"),
        None,
        None,
    ]

    calls = []

    async def flaky(msg, **kwargs):
        calls.append(kwargs)
        outcome = responses.pop(0)
        if outcome is not None:
            raise outcome

    monkeypatch.setattr(email_service.aiosmtplib, "send", flaky)
    monkeypatch.setattr(email_service.asyncio, "sleep", _no_sleep)

    await send_otp_email("user@example.com", "123456", "password_reset")

    assert len(calls) == 2, "le retry doit s'arrêter dès que l'envoi passe"


# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "missing", ["email_username", "email_password", "default_from_email"]
)
async def test_incomplete_configuration_raises_immediately(monkeypatch, missing):
    """Identifiants absents : échec immédiat, aucun appel réseau."""
    _configure(monkeypatch, **{missing: ""})
    calls = _install_smtp(monkeypatch)

    with pytest.raises(EmailNotConfiguredError):
        await send_otp_email("user@example.com", "123456", "password_reset")

    assert calls == [], "une config incomplète ne doit pas atteindre le réseau"


def test_email_configured_requires_all_three_credentials(monkeypatch):
    _configure(monkeypatch)
    assert settings.email_configured is True

    for missing in ("email_username", "email_password", "default_from_email"):
        _configure(monkeypatch, **{missing: ""})
        assert settings.email_configured is False


def test_email_configured_is_true_for_gmail_defaults(monkeypatch):
    """Le triplet minimal attendu en production."""
    _configure(
        monkeypatch,
        email_username="interviewprep@gmail.com",
        email_password="abcd efgh ijkl mnop",
        default_from_email="interviewprep@gmail.com",
    )

    assert settings.email_configured is True
