"""Service de reinitialisation de mot de passe (business logic uniquement)."""

from __future__ import annotations

import random
import string
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.services.auth_service import get_user_by_email, hash_password
from app.services.email_service import send_reset_email

FORGOT_CODE_TTL_MINUTES = 30
FORGOT_CODE_LENGTH = 6


def generate_reset_code() -> str:
    return "".join(random.choices(string.digits, k=FORGOT_CODE_LENGTH))


def code_is_expired(expires_at: datetime | str | None) -> bool:

    if expires_at is None:
        return True

    if isinstance(expires_at, str):
        try:
            expires_at = datetime.fromisoformat(expires_at)
        except ValueError:
            return True

    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)

    return datetime.now(timezone.utc) > expires_at


async def create_password_reset_code(db: AsyncSession, email: str) -> tuple[User | None, str | None]:
    """Crée (ou remplace) le code de reset pour un utilisateur."""
    user = await get_user_by_email(db, email.lower())
    if not user:
        return None, None

    user.reset_code = generate_reset_code()
    user.reset_code_expires_at = (datetime.now(timezone.utc) + timedelta(minutes=FORGOT_CODE_TTL_MINUTES)).isoformat()
    db.add(user)
    await db.commit()
    await db.refresh(user)

    return user, user.reset_code


async def send_password_reset_code_if_user_exists(
    db: AsyncSession,
    email: str,
    background_tasks: BackgroundTasks,
) -> dict[str, Optional[object]]:
    """Convenience: crée le code puis planifie l'envoi de l'email."""
    user, code = await create_password_reset_code(db, email)
    if not user or not code:
        # On ne révèle pas l'existence du compte
        return {"sent": False}

    background_tasks.add_task(send_reset_email, email, code)
    return {"sent": True, "expires_in_minutes": FORGOT_CODE_TTL_MINUTES}


async def verify_password_reset_code(db: AsyncSession, email: str, code: str) -> bool:
    user = await get_user_by_email(db, email.lower())
    return bool(user and user.reset_code == code and not code_is_expired(user.reset_code_expires_at))


async def reset_user_password(db: AsyncSession, email: str, code: str, new_password: str) -> bool:
    user = await get_user_by_email(db, email.lower())
    if not user or user.reset_code != code or code_is_expired(user.reset_code_expires_at):
        return False

    user.mot_de_passe_hash = hash_password(new_password)
    user.reset_code = None
    user.reset_code_expires_at = None
    db.add(user)
    await db.commit()
    return True

