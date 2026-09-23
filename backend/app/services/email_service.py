"""SMTP email jobs with explicit logging and bounded retries."""
import asyncio
import logging
from email.message import EmailMessage
import aiosmtplib
from app.config.settings import settings

logger = logging.getLogger(__name__)


async def _send(msg: EmailMessage, recipient: str, max_retries: int = 3) -> None:
    if not settings.email_username or not settings.email_password:
        logger.error("Email skipped: SMTP credentials are not configured")
        return
    for attempt in range(1, max_retries + 1):
        try:
            logger.info("Sending email attempt %d/%d to %s", attempt, max_retries, recipient)
            await aiosmtplib.send(
                msg, hostname=settings.email_host, port=settings.email_port,
                username=settings.email_username, password=settings.email_password,
                start_tls=settings.email_use_tls, use_tls=settings.email_use_ssl, timeout=10,
            )
            logger.info("Email sent to %s", recipient)
            return
        except (aiosmtplib.SMTPException, asyncio.TimeoutError) as exc:
            logger.warning("Email attempt %d failed for %s: %s", attempt, recipient, exc)
            if attempt < max_retries:
                await asyncio.sleep(2 ** attempt)
        except Exception:
            logger.exception("Unexpected email failure for %s", recipient)
            break
    logger.error("Email permanently failed for %s after %d attempts", recipient, max_retries)


async def send_reset_email(email: str, code: str, max_retries: int = 3) -> None:
    msg = EmailMessage()
    msg["Subject"] = "InterviewPrep - Réinitialisation de mot de passe"
    msg["From"] = settings.default_from_email
    msg["To"] = email
    msg.set_content(f"Votre code de réinitialisation InterviewPrep est : {code}\n\nIl expire dans 30 minutes.")
    await _send(msg, email, max_retries)


async def send_otp_email(email: str, code: str, purpose: str, max_retries: int = 3) -> None:
    label = {"login_2fa": "connexion", "password_reset": "réinitialisation"}.get(purpose, "vérification")
    msg = EmailMessage()
    msg["Subject"] = "InterviewPrep - Code de sécurité"
    msg["From"] = settings.default_from_email
    msg["To"] = email
    msg.set_content(f"Votre code de {label} InterviewPrep est : {code}\n\nIl expire dans {settings.email_otp_ttl_minutes} minutes.")
    await _send(msg, email, max_retries)
