"""Envoi d'emails transactionnels.

Deux transports sont supportés :

* **Brevo** (par défaut dès que ``BREVO_API_KEY`` est défini) — API REST en
  HTTPS/443. Les plateformes cloud (Render, Railway…) bloquent fréquemment les
  ports SMTP sortants, ce qui rend le SMTP inutilisable en production.
* **SMTP** — conservé pour le développement local et les déploiements où le
  port 587 est autorisé.

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
import httpx

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
_TRANSIENT_SMTP_CODES = {
    aiosmtplib.SMTPConnectError,
    aiosmtplib.SMTPServerDisconnected,
    aiosmtplib.SMTPResponseException,
    aiosmtplib.SMTPTimeoutError,
    ConnectionError,
    asyncio.TimeoutError,
    OSError,
}


def _is_transient_smtp_error(exc: Exception) -> bool:
    if isinstance(exc, aiosmtplib.SMTPResponseException):
        # 4xx = erreur temporaire (421, 450, 451…) ; 5xx = rejet définitif.
        return 400 <= exc.code < 500
    return isinstance(exc, _TRANSIENT_SMTP_CODES)


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
            "(ou definez EMAIL_PROVIDER=brevo avec BREVO_API_KEY)."
        )


async def _send_via_brevo(msg: EmailMessage, recipient: str) -> None:
    """Remet l'email via l'API REST Brevo (HTTPS/443)."""
    if not settings.brevo_api_key:
        raise EmailNotConfiguredError("BREVO_API_KEY n'est pas configuré.")
    if not settings.default_from_email:
        raise EmailNotConfiguredError("DEFAULT_FROM_EMAIL n'est pas configuré.")

    payload = {
        "sender": {
            "name": _message_from_name_setting(),
            "email": settings.default_from_email,
        },
        "to": [{"email": recipient}],
        "subject": msg["Subject"] or "",
        "text": msg.get_content(),
    }
    headers = {
        "api-key": settings.brevo_api_key,
        "accept": "application/json",
        "content-type": "application/json",
    }

    try:
        async with httpx.AsyncClient(
            timeout=settings.email_http_timeout_seconds
        ) as client:
            response = await client.post(
                settings.brevo_api_url, json=payload, headers=headers
            )
    except (httpx.TimeoutException, httpx.HTTPError, OSError) as exc:
        raise EmailDeliveryError(
            f"Échec de l'appel Brevo : {exc}", transient=True
        ) from exc

    if response.status_code >= 400:
        # 429 et 5xx sont transitoires ; 4xx (clé invalide, expéditeur non
        # vérifié) ne se répare pas en réessayant.
        transient = response.status_code == 429 or response.status_code >= 500
        raise EmailDeliveryError(
            f"Brevo a refusé l'envoi (HTTP {response.status_code}) : "
            f"{_brevo_error_detail(response)}",
            transient=transient,
        )


def _brevo_error_detail(response: httpx.Response) -> str:
    """Extrait le champ ``message`` d'une réponse d'erreur Brevo, si présent."""
    try:
        body = response.json()
    except ValueError:
        return response.text[:300]
    if isinstance(body, dict):
        message = body.get("message") or body.get("code")
        if message:
            return str(message)[:300]
    return str(body)[:300]


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
            timeout=settings.email_http_timeout_seconds,
        )
    except (aiosmtplib.SMTPException, asyncio.TimeoutError, OSError) as exc:
        raise EmailDeliveryError(
            f"Échec de l'envoi SMTP : {exc}",
            transient=_is_transient_smtp_error(exc),
        ) from exc


async def _dispatch(msg: EmailMessage, recipient: str) -> None:
    if settings.resolved_email_provider == "brevo":
        await _send_via_brevo(msg, recipient)
    else:
        await _send_via_smtp(msg, recipient)


async def _send(msg: EmailMessage, recipient: str, max_retries: int = 3) -> None:
    """Envoie l'email en réessayant uniquement les erreurs transitoires.

    Lève ``EmailDeliveryError`` si la livraison échoue : c'est ce qui permet
    à l'appelant de ne pas annoncer un succès à l'utilisateur.
    """
    if not settings.email_configured:
        logger.error("Email skipped: no transport configured")
        raise EmailNotConfiguredError(
            "Aucun transport d'email configuré "
            "(BREVO_API_KEY ou SMTP_USER/SMTP_PASSWORD + DEFAULT_FROM_EMAIL)."
        )

    provider = settings.resolved_email_provider
    last_error: EmailDeliveryError | None = None

    for attempt in range(1, max_retries + 1):
        try:
            logger.info(
                "Sending email attempt %d/%d to %s via %s",
                attempt,
                max_retries,
                recipient,
                provider,
            )
            await _dispatch(msg, recipient)
            logger.info("Email sent to %s via %s", recipient, provider)
            return
        except EmailDeliveryError as exc:
            if isinstance(exc, EmailNotConfiguredError) or not exc.transient:
                # Un défaut de configuration ou un rejet définitif ne se
                # répare pas en réessayant : on échoue immédiatement.
                logger.error(
                    "Email permanently failed for %s via %s: %s",
                    recipient,
                    provider,
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
