"""Envoi d'emails transactionnels.

Transport unique : SMTP en soumission authentifiée (port 587 + STARTTLS par
défaut, `smtp.gmail.com` en production).

Invariant central : toute erreur de livraison est **propagée** via
``EmailDeliveryError``. Le code appelant doit pouvoir distinguer « envoyé » de
« échec », sinon l'API répond un succès mensonger à l'utilisateur.
"""

from __future__ import annotations

import asyncio
import logging
from email.message import EmailMessage
from email.utils import formataddr, parseaddr

import aiosmtplib

from app.config.settings import settings

logger = logging.getLogger(__name__)


class EmailDeliveryError(Exception):
    """L'email n'a pas pu être remis au fournisseur de transport.

    ``transient`` indique si un nouvel essai a une chance de réussir : les
    erreurs de configuration et les rejets définitifs (4xx, 5xx) en sont
    exempts, ce qui évite trois tentatives inutiles sur un mot de passe
    invalide.
    """

    transient = False

    def __init__(self, message: str, *, transient: bool = False):
        super().__init__(message)
        self.transient = transient


class EmailNotConfiguredError(EmailDeliveryError):
    """Aucun transport d'email n'est configuré (identifiants absents)."""


# Erreurs SMTP qui justifient un nouvel essai : réseau instable, indisponibilité
# temporaire, limite de débit. Les erreurs d'authentification (535/534) en sont
# exclues : réessayer trois fois un mot de passe invalide n'aide personne.
#
# Doit être un **tuple** : `isinstance()` refuse un set en second argument et
# lèverait TypeError, avalé en « erreur inattendue » — donc aucun retry, et la
# cause réelle (connexion refusée, port bloqué) perdue dans les logs.
_TRANSIENT_SMTP_ERRORS = (
    aiosmtplib.SMTPConnectError,
    aiosmtplib.SMTPServerDisconnected,
    aiosmtplib.SMTPResponseException,
    aiosmtplib.SMTPTimeoutError,
    ConnectionError,
    asyncio.TimeoutError,
    OSError,
)


def _is_transient_smtp_error(exc: Exception) -> bool:
    if isinstance(exc, aiosmtplib.SMTPResponseException):
        # 4xx = erreur temporaire (421, 450, 451…) ; 5xx = rejet définitif.
        return 400 <= exc.code < 500
    return isinstance(exc, _TRANSIENT_SMTP_ERRORS)


def _message_from_name_setting() -> str:
    """Nom d'expéditeur par défaut, dérivé de DEFAULT_FROM_EMAIL."""
    _, address = parseaddr(settings.default_from_email or "")
    if "@" not in address:
        return "InterviewPrep"
    return address.split("@", 1)[0]


def _sender() -> str:
    return formataddr((_message_from_name_setting(), settings.default_from_email))


def _require_smtp_credentials() -> None:
    if not settings.email_username or not settings.email_password:
        raise EmailNotConfiguredError(
            "SMTP_USER / SMTP_PASSWORD ne sont pas configurés "
            "(pour Gmail : un mot de passe d'application, pas le mot de passe "
            "du compte)."
        )


async def _send_via_smtp(msg: EmailMessage, recipient: str) -> None:
    _require_smtp_credentials()
    try:
        await aiosmtplib.send(
            msg,
            hostname=settings.email_host,
            port=settings.email_port,
            username=settings.email_username,
            password=settings.email_password,
            start_tls=settings.email_use_tls,
            use_tls=settings.email_use_ssl,
            timeout=settings.email_timeout_seconds,
        )
    except (aiosmtplib.SMTPException, asyncio.TimeoutError, OSError) as exc:
        raise EmailDeliveryError(
            f"Échec de l'envoi SMTP ({settings.email_host}:{settings.email_port}) : {exc}",
            transient=_is_transient_smtp_error(exc),
        ) from exc


async def _send(msg: EmailMessage, recipient: str, max_retries: int = 3) -> None:
    """Envoie l'email en réessayant uniquement les erreurs transitoires.

    Lève ``EmailDeliveryError`` si la livraison échoue : c'est ce qui permet
    à l'appelant de ne pas annoncer un succès à l'utilisateur.
    """
    if not settings.email_configured:
        logger.error("Email skipped: no transport configured")
        raise EmailNotConfiguredError(
            "Transport SMTP incomplet : SMTP_USER, SMTP_PASSWORD et "
            "DEFAULT_FROM_EMAIL doivent être définis."
        )

    last_error: EmailDeliveryError | None = None

    for attempt in range(1, max_retries + 1):
        try:
            logger.info(
                "Sending email attempt %d/%d to %s via %s:%s",
                attempt,
                max_retries,
                recipient,
                settings.email_host,
                settings.email_port,
            )
            await _send_via_smtp(msg, recipient)
            logger.info("Email sent to %s", recipient)
            return
        except EmailDeliveryError as exc:
            if isinstance(exc, EmailNotConfiguredError) or not exc.transient:
                # Un défaut de configuration ou un rejet définitif ne se
                # répare pas en réessayant : on échoue immédiatement.
                logger.error(
                    "Email permanently failed for %s via %s:%s: %s",
                    recipient,
                    settings.email_host,
                    settings.email_port,
                    exc,
                )
                raise
            last_error = exc
            logger.warning(
                "Email attempt %d failed for %s: %s", attempt, recipient, exc
            )
            if attempt < max_retries:
                await asyncio.sleep(2**attempt)
        except Exception as exc:
            logger.exception("Unexpected email failure for %s", recipient)
            raise EmailDeliveryError(
                f"Erreur inattendue d'envoi vers {recipient}"
            ) from exc

    raise EmailDeliveryError(
        f"Email permanently failed for {recipient} after {max_retries} attempts: "
        f"{last_error}"
    )


async def send_otp_email(
    email: str, code: str, purpose: str, max_retries: int = 3
) -> None:
    """Envoie un code OTP. Lève ``EmailDeliveryError`` en cas d'échec."""
    label = {
        "login_2fa": "connexion",
        "password_reset": "réinitialisation",
    }.get(purpose, "vérification")
    ttl = (
        settings.email_otp_ttl_minutes
        if purpose != "password_reset"
        else settings.password_reset_code_ttl_minutes
    )
    msg = EmailMessage()
    msg["Subject"] = "InterviewPrep - Code de sécurité"
    msg["From"] = _sender()
    msg["To"] = email
    msg.set_content(
        f"Votre code de {label} InterviewPrep est : {code}\n\n"
        f"Il expire dans {ttl} minutes."
    )
    await _send(msg, email, max_retries)
