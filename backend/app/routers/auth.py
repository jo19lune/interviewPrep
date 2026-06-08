"""Router d'authentification - register, login, refresh, delete."""

import random
import string
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AuthenticationError
from app.core.security import get_current_user
from app.data.database import get_db
from app.models.user import User
from app.schemas.user import (
    AuthResponse,
    TokenRefreshRequest,
    UserLoginRequest,
    UserRegisterRequest,
    UserResponse,
)
from app.services.auth_service import (
    authenticate_user,
    get_user_by_email,
    hash_password,
    refresh_user_tokens,
)

router = APIRouter(prefix="/auth", tags=["authentication"])

FORGOT_CODE_TTL_MINUTES = 30
FORGOT_CODE_LENGTH = 6


class ForgotPasswordRequest(BaseModel):
    courriel: EmailStr


class VerifyResetCodeRequest(BaseModel):
    courriel: EmailStr
    code: str = Field(..., min_length=6, max_length=6)


class ResetPasswordRequest(BaseModel):
    courriel: EmailStr
    code: str = Field(..., min_length=6, max_length=6)
    nouveau_mot_de_passe: str = Field(..., min_length=8, max_length=100)


def _generate_reset_code() -> str:
    return "".join(random.choices(string.digits, k=FORGOT_CODE_LENGTH))


def _code_is_expired(expires_at: datetime | None) -> bool:
    if expires_at is None:
        return True
    return datetime.now(timezone.utc) > expires_at


@router.post("/forgot-password")
async def forgot_password(request: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    user = await get_user_by_email(db, request.courriel.lower())
    if not user:
        return {"message": "Si ce compte existe, un code de réinitialisation a été envoyé."}

    user.reset_code = _generate_reset_code()
    user.reset_code_expires_at = datetime.now(timezone.utc) + timedelta(minutes=FORGOT_CODE_TTL_MINUTES)
    db.add(user)
    await db.commit()
    await db.refresh(user)

    return {
        "message": "Code de réinitialisation généré (valable 30 minutes).",
        "expires_in_minutes": FORGOT_CODE_TTL_MINUTES,
    }


@router.post("/verify-reset-code")
async def verify_reset_code(request: VerifyResetCodeRequest, db: AsyncSession = Depends(get_db)):
    user = await get_user_by_email(db, request.courriel.lower())
    if not user or user.reset_code != request.code or _code_is_expired(user.reset_code_expires_at):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code invalide ou expiré.",
        )
    return {"valid": True}


@router.post("/reset-password")
async def reset_password(request: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    user = await get_user_by_email(db, request.courriel.lower())
    if not user or user.reset_code != request.code or _code_is_expired(user.reset_code_expires_at):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code invalide ou expiré.",
        )

    user.mot_de_passe_hash = hash_password(request.nouveau_mot_de_passe)
    user.reset_code = None
    user.reset_code_expires_at = None
    db.add(user)
    await db.commit()

    return {"message": "Mot de passe réinitialisé avec succès."}
