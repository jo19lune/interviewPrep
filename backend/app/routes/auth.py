"""Router d'authentification - register, login, refresh, delete, forgot password."""

import asyncio
import random
import string
import time
from datetime import datetime, timedelta, timezone
import logging
from typing import Dict, Tuple

from email.message import EmailMessage
import aiosmtplib
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status, Request
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
from app.schemas.auth import (
    ForgotPasswordRequest,
    VerifyResetCodeRequest,
    ResetPasswordRequest,
)
from app.services.auth_service import (
    authenticate_user,
    get_user_by_email,
    hash_password,
    refresh_user_tokens,
)
from app.services.password_reset_service import (
    send_password_reset_code_if_user_exists,
    verify_password_reset_code,
    reset_user_password,
)

router = APIRouter(prefix="/auth", tags=["authentication"])
logger = logging.getLogger(__name__)

# Basic in-memory rate limiter for login
login_attempts: Dict[str, Tuple[int, float]] = {}
MAX_ATTEMPTS = 5
LOCKOUT_TIME = 300 # 5 minutes

def check_rate_limit(email: str):
    now = time.time()
    if email in login_attempts:
        attempts, last_attempt = login_attempts[email]
        if attempts >= MAX_ATTEMPTS:
            if now - last_attempt < LOCKOUT_TIME:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Trop de tentatives de connexion. Veuillez réessayer plus tard.",
                )
            else:
                # Reset after lockout period
                login_attempts[email] = (0, now)
    else:
        login_attempts[email] = (0, now)

def record_failed_attempt(email: str):
    now = time.time()
    if email in login_attempts:
        attempts, _ = login_attempts[email]
        login_attempts[email] = (attempts + 1, now)
    else:
        login_attempts[email] = (1, now)

def clear_attempts(email: str):
    if email in login_attempts:
        del login_attempts[email]

@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(request: UserRegisterRequest, db: AsyncSession = Depends(get_db)):
    """Creer un nouveau compte utilisateur."""
    email = request.courriel
    existing_user = await get_user_by_email(db, email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )

    try:
        new_user = User(
            courriel=email,
            mot_de_passe_hash=hash_password(request.mot_de_passe),
            prenom=request.prenom,
            nom=request.nom,
            est_actif=True,
        )
        db.add(new_user)
        await db.commit()
        await db.refresh(new_user)
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )

    _, tokens = await authenticate_user(db, email, request.mot_de_passe)
    return AuthResponse(
        **tokens.model_dump(),
        user=UserResponse.model_validate(new_user),
    )

@router.post("/login", response_model=AuthResponse)
async def login(request: UserLoginRequest, request_info: Request, db: AsyncSession = Depends(get_db)):
    """Authentifier un utilisateur."""
    client_ip = request_info.client.host if request_info.client else "unknown"
    rate_limit_key = f"{request.courriel}_{client_ip}"
    check_rate_limit(rate_limit_key)
    
    try:
        user, tokens = await authenticate_user(db, request.courriel, request.mot_de_passe)
        clear_attempts(rate_limit_key)
    except AuthenticationError as e:
        record_failed_attempt(rate_limit_key)
        await asyncio.sleep(1) # delay to thwart timing attacks
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=e.message,
        )

    return AuthResponse(
        **tokens.model_dump(),
        user=UserResponse.model_validate(user),
    )

@router.post("/refresh", response_model=AuthResponse)
async def refresh(request: TokenRefreshRequest, db: AsyncSession = Depends(get_db)):
    """Rafraichir les tokens avec un refresh token valide."""
    try:
        user, new_tokens = await refresh_user_tokens(db, request.refresh_token)
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=e.message,
        )

    return AuthResponse(
        **new_tokens.model_dump(),
        user=UserResponse.model_validate(user),
    )

@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """Recuperer les informations de l'utilisateur courant."""
    return UserResponse.model_validate(current_user)

@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Supprimer le compte utilisateur et ses donnees liees definitivement."""
    await db.delete(current_user)
    await db.commit()
    return None

@router.post("/forgot-password")
async def forgot_password(
    request: ForgotPasswordRequest,
    background_tasks: BackgroundTasks,
    request_info: Request,
    db: AsyncSession = Depends(get_db),
):
    client_ip = request_info.client.host if request_info.client else "unknown"
    rate_limit_key = f"forgot_{client_ip}"
    check_rate_limit(rate_limit_key)
    
    result = await send_password_reset_code_if_user_exists(db, request.courriel, background_tasks)
    # Ne pas révéler l'existence du compte
    if not result.get("sent"):
        record_failed_attempt(rate_limit_key)
        await asyncio.sleep(0.5) # Generic short delay to mitigate timing attacks even further
        return {"message": "Si ce compte existe, un code de reinitialisation a ete envoye."}

    clear_attempts(rate_limit_key)
    return {
        "message": "Code de reinitialisation envoye a votre adresse email.",
        "expires_in_minutes": result.get("expires_in_minutes"),
    }

@router.post("/verify-reset-code")
async def verify_reset_code(
    request: VerifyResetCodeRequest,
    db: AsyncSession = Depends(get_db),
):
    valid = await verify_password_reset_code(db, request.courriel, request.code)
    if not valid:
        await asyncio.sleep(1)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code invalide ou expire.",
        )
    return {"valid": True}

@router.post("/reset-password")
async def reset_password(
    request: ResetPasswordRequest,
    db: AsyncSession = Depends(get_db),
):
    ok = await reset_user_password(
        db,
        request.courriel,
        request.code,
        request.nouveau_mot_de_passe,
    )
    if not ok:
        await asyncio.sleep(1)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code invalide ou expire.",
        )

    return {"message": "Mot de passe reinitialise avec succes."}

