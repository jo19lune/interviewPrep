"""
Router d'authentification.

Ce module gère tous les endpoints relatifs à la sécurité et aux comptes :
inscription (register), connexion (login), rafraîchissement de jetons
(refresh), suppression de compte et récupération de mot de passe.
"""

import asyncio
import logging

from fastapi import (
    APIRouter,
    BackgroundTasks,
    Depends,
    HTTPException,
    Request,
    status,
)
from fastapi.security import HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AuthenticationError
from app.config.settings import settings
from app.core.rate_limit import check_rate_limit, clear_attempts, record_failed_attempt
from app.core.security import get_current_user, security
from app.data.database import get_db
from app.models.user import User
from app.schemas.user import (
    AuthResponse,
    TokenRefreshRequest,
    UserLoginRequest,
    UserRegisterRequest,
    UserResponse,
    LoginResponse,
)
from app.schemas.auth import GoogleLoginRequest, LoginOTPRequest
from app.services.auth_service import (
    authenticate_user,
    authenticate_google_user,
    get_user_by_email,
    refresh_user_tokens,
    register_new_user,
    revoke_token,
)
from app.services.otp_service import consume_otp, issue_otp

router = APIRouter(prefix="/auth", tags=["authentication"])
logger = logging.getLogger(__name__)


@router.post(
    "/register",
    response_model=AuthResponse,
    status_code=status.HTTP_201_CREATED,
)
async def register(
    request: UserRegisterRequest, db: AsyncSession = Depends(get_db)
):
    """
    Inscrit un nouvel utilisateur.
    """
    request_data = {
        "courriel": request.courriel,
        "mot_de_passe": request.mot_de_passe,
        "prenom": request.prenom,
        "nom": request.nom,
    }
    user, tokens = await register_new_user(db, request_data)
    return AuthResponse(
        **tokens.model_dump(),
        user=UserResponse.model_validate(user),
    )


@router.post("/login", response_model=LoginResponse)
async def login(
    request: UserLoginRequest, 
    request_info: Request, 
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db)
):
    """
    Authentifie un utilisateur existant.
    """
    client_ip = request_info.client.host if request_info.client else "unknown"
    rate_limit_key = f"{request.courriel}_{client_ip}"
    check_rate_limit(rate_limit_key)
    
    try:
        user, tokens = await authenticate_user(
            db, request.courriel, request.mot_de_passe
        )
        clear_attempts(rate_limit_key)
    except AuthenticationError as e:
        record_failed_attempt(rate_limit_key)
        await asyncio.sleep(1)  # Délai anti-timing attack
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=e.message,
        )

    if settings.email_2fa_enabled:
        await issue_otp(db, user.courriel, "login_2fa", background_tasks=background_tasks, user_id=user.id,
                        ttl_minutes=settings.email_2fa_otp_ttl_minutes)
        return LoginResponse(requires_2fa=True, challenge_expires_in_seconds=settings.email_2fa_otp_ttl_minutes * 60,
                             user=UserResponse.model_validate(user))
    return LoginResponse(**tokens.model_dump(), user=UserResponse.model_validate(user))


@router.post("/login/verify-otp", response_model=AuthResponse)
async def verify_login_otp(request: LoginOTPRequest, db: AsyncSession = Depends(get_db)):
    user = await get_user_by_email(db, request.courriel)
    if not user or not await consume_otp(db, request.courriel, "login_2fa", request.code):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired verification code")
    from app.services.auth_tokens import create_access_token, create_refresh_token
    return AuthResponse(access_token=create_access_token(str(user.id)),
                        refresh_token=create_refresh_token(str(user.id)),
                        user=UserResponse.model_validate(user))


@router.post("/google", response_model=AuthResponse)
async def google_login(request: GoogleLoginRequest, db: AsyncSession = Depends(get_db)):
    try:
        if not settings.google_client_id:
            raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Google login is not configured")
        from google.auth.transport import requests as google_requests
        from google.oauth2 import id_token
        claims = id_token.verify_oauth2_token(request.id_token, google_requests.Request(), settings.google_client_id or None)
        if claims.get("iss") not in {"accounts.google.com", "https://accounts.google.com"} or not claims.get("email_verified"):
            raise ValueError("Unverified Google identity")
        user, tokens = await authenticate_google_user(db, claims)
    except HTTPException:
        raise
    except Exception as exc:
        logger.exception("Google token verification failed")
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Google identity token") from exc
    return AuthResponse(**tokens.model_dump(), user=UserResponse.model_validate(user))


@router.post("/refresh", response_model=AuthResponse)
async def refresh(
    request: TokenRefreshRequest, db: AsyncSession = Depends(get_db)
):
    """
    Génère une nouvelle paire de tokens à l'aide d'un Refresh Token valide.
    """
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
    """
    Récupère le profil de l'utilisateur courant.
    """
    return UserResponse.model_validate(current_user)


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Supprime définitivement le compte utilisateur.
    """
    await db.delete(current_user)
    await db.commit()
    return None


@router.post("/logout", status_code=status.HTTP_200_OK)
async def logout(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
):
    """
    Déconnecte l'utilisateur en ajoutant son token à la blocklist.
    """
    if credentials:
        await revoke_token(db, credentials.credentials)
    return {"message": "Déconnexion réussie"}
