"""Service d'envoi d'emails."""

import logging
import asyncio
from email.message import EmailMessage

import aiosmtplib

from app.config.settings import settings

logger = logging.getLogger(__name__)


async def send_reset_email(email: str, code: str, max_retries: int = 3) -> None:
    """Envoyer le code de reinitialisation, si SMTP est configure, avec retries et logs complets."""
    logger.info("Début de la tâche de fond : Envoi de l'email de réinitialisation à %s", email)
    
    if not settings.email_username or not settings.email_password:
        logger.error("Échec critique : Identifiants SMTP manquants. L'email n'a pas pu être envoyé.")
        return

    msg = EmailMessage()
    msg["Subject"] = "InterviewPrep - Réinitialisation de mot de passe"
    msg["From"] = settings.default_from_email
    msg["To"] = email
    msg.set_content(
        f"""Bonjour,

Votre code de reinitialisation de mot de passe est : {code}

Ce code est valable 30 minutes.

InterviewPrep"""
    )

    for attempt in range(1, max_retries + 1):
        try:
            logger.debug("Tentative %d/%d de l'envoi SMTP...", attempt, max_retries)
            await aiosmtplib.send(
                msg,
                hostname=settings.email_host,
                port=settings.email_port,
                username=settings.email_username,
                password=settings.email_password,
                start_tls=settings.email_use_tls,
                timeout=10
            )
            logger.info("Succès : Email de réinitialisation envoyé à %s", email)
            return
            
        except aiosmtplib.SMTPException as exc:
            logger.warning("Tentative %d échouée (Erreur SMTP) : %s", attempt, exc)
        except asyncio.TimeoutError:
            logger.warning("Tentative %d échouée (Timeout).", attempt)
        except Exception as exc:
            logger.exception("Erreur inattendue lors de l'envoi de l'email à %s.", email)
            break
            
        if attempt < max_retries:
            await asyncio.sleep(2 ** attempt)

    logger.error("Échec définitif : L'email pour %s n'a pas pu être envoyé après %d tentatives.", email, max_retries)
