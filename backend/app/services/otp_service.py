"""Reusable, single-use email OTP persistence and delivery."""
from __future__ import annotations
import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone
from fastapi import BackgroundTasks
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from app.config.settings import settings
from app.models.email_otp import EmailOTP
from app.services.email_service import send_otp_email


def _hash(code: str) -> str:
    return hmac.new(settings.secret_key.encode(), code.encode(), hashlib.sha256).hexdigest()


async def issue_otp(db: AsyncSession, email: str, purpose: str, background_tasks: BackgroundTasks | None = None, user_id=None, ttl_minutes: int | None = None) -> str:
    email = email.strip().lower()
    await db.execute(update(EmailOTP).where(EmailOTP.email == email, EmailOTP.purpose == purpose, EmailOTP.consumed.is_(False)).values(consumed=True))
    code = f"{secrets.randbelow(1_000_000):06d}"
    db.add(EmailOTP(email=email, user_id=user_id, purpose=purpose, code_hash=_hash(code),
                    expires_at=datetime.now(timezone.utc) + timedelta(minutes=ttl_minutes or settings.email_otp_ttl_minutes),
                    max_attempts=settings.email_otp_max_attempts))
    await db.commit()
    if background_tasks:
        background_tasks.add_task(send_otp_email, email, code, purpose)
    return code


async def consume_otp(db: AsyncSession, email: str, purpose: str, code: str) -> bool:
    result = await db.execute(select(EmailOTP).where(
        EmailOTP.email == email.strip().lower(), EmailOTP.purpose == purpose,
        EmailOTP.consumed.is_(False)).order_by(EmailOTP.cree_le.desc()))
    otp = result.scalars().first()
    now = datetime.now(timezone.utc)
    if not otp or otp.expires_at.replace(tzinfo=timezone.utc) <= now or otp.attempts >= otp.max_attempts:
        return False
    otp.attempts += 1
    valid = hmac.compare_digest(otp.code_hash, _hash(code))
    if valid:
        otp.consumed = True
    await db.commit()
    return valid


async def validate_otp(db: AsyncSession, email: str, purpose: str, code: str) -> bool:
    """Validate without consuming; the state-changing operation consumes it."""
    result = await db.execute(select(EmailOTP).where(
        EmailOTP.email == email.strip().lower(), EmailOTP.purpose == purpose,
        EmailOTP.consumed.is_(False)).order_by(EmailOTP.cree_le.desc()))
    otp = result.scalars().first()
    return bool(otp and otp.attempts < otp.max_attempts and
                otp.expires_at.replace(tzinfo=timezone.utc) > datetime.now(timezone.utc) and
                hmac.compare_digest(otp.code_hash, _hash(code)))
