"""Service d'envoi d'emails."""

import logging
from email.message import EmailMessage

import aiosmtplib

from app.config.settings import settings

logger = logging.getLogger(__name__)


async def send_reset_email(email: str, code: str) -> None:
    """Envoyer le code de reinitialisation, si SMTP est configure."""
    if not settings.email_username or not settings.email_password:
        return

    msg = EmailMessage()
    msg["Subject"] = "InterviewPrep - Reinitialisation de mot de passe"
    msg["From"] = settings.default_from_email
    msg["To"] = email
    msg.set_content(
        f"""Bonjour,

Votre code de reinitialisation de mot de passe est: {code}

Ce code est valable 30 minutes.

InterviewPrep"""
    )

    try:
        await aiosmtplib.send(
            msg,
            hostname=settings.email_host,
            port=settings.email_port,
            username=settings.email_username,
            password=settings.email_password,
            start_tls=settings.email_use_tls,
        )
    except Exception as exc:
        logger.error("Failed to send reset email: %s", exc)
