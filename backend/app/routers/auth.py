"""
Router d'authentification.

Ce module gère tous les endpoints relatifs à la sécurité et aux comptes :
inscription (register), connexion (login), rafraîchissement de jetons (refresh),
suppression de compte et récupération de mot de passe (forgot-password).
"""

import asyncio
import logging
import time
from typing import Dict, Tuple

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AuthenticationError
from app.core.security import get_current_user
from app.data.database import get_db
from app.models.user import User
from app.schemas.auth import (
    ForgotPasswordRequest,
    ResetPasswordRequest,
    VerifyResetCodeRequest,
)
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
from app.services.password_reset_service import (
    reset_user_password,
    send_password_reset_code_if_user_exists,
    verify_password_reset_code,
)

router = APIRouter(prefix="/auth", tags=["authentication"])
logger = logging.getLogger(__name__)

# Limitation de requêtes (Rate Limiting) basique en mémoire pour les connexions
login_attempts: Dict[str, Tuple[int, float]] = {}
MAX_ATTEMPTS = 5
LOCKOUT_TIME = 300  # 5 minutes


def check_rate_limit(key: str) -> None:
    """
    Vérifie si une clé (email ou IP) a dépassé la limite de requêtes autorisées.

    Args:
        key (str): La clé unique à vérifier.

    Raises:
        HTTPException: Erreur 429 si la limite est atteinte.
    """
    now = time.time()
    if key in login_attempts:
        attempts, last_attempt = login_attempts[key]
        if attempts >= MAX_ATTEMPTS:
            if now - last_attempt < LOCKOUT_TIME:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Trop de tentatives de connexion. Veuillez réessayer plus tard.",
                )
            else:
                # Réinitialisation après la période de blocage
                login_attempts[key] = (0, now)
    else:
        login_attempts[key] = (0, now)


def record_failed_attempt(key: str) -> None:
    """Incrémente le compteur d'échecs pour une clé donnée."""
    now = time.time()
    if key in login_attempts:
        attempts, _ = login_attempts[key]
        login_attempts[key] = (attempts + 1, now)
    else:
        login_attempts[key] = (1, now)


def clear_attempts(key: str) -> None:
    """Efface l'historique d'échecs en cas de succès."""
    if key in login_attempts:
        del login_attempts[key]


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(request: UserRegisterRequest, db: AsyncSession = Depends(get_db)):
    """
    Inscrit un nouvel utilisateur.

    Vérifie que l'email n'existe pas, crée le compte, puis génère
    immédiatement les jetons d'accès.

    Args:
        request (UserRegisterRequest): Les données d'inscription.
        db (AsyncSession): Session de la base de données.

    Returns:
        AuthResponse: Les informations utilisateur et les jetons JWT.

    Raises:
        HTTPException: Erreur 409 si l'email est déjà pris.
    """
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
async def login(
    request: UserLoginRequest, 
    request_info: Request, 
    db: AsyncSession = Depends(get_db)
):
    """
    Authentifie un utilisateur existant.

    Protégé contre les attaques par force brute grâce au rate-limiting.

    Args:
        request (UserLoginRequest): Les identifiants (email, mot de passe).
        request_info (Request): Informations sur la requête HTTP pour extraire l'IP.
        db (AsyncSession): Session de la base de données.

    Returns:
        AuthResponse: Les tokens d'accès et les détails de l'utilisateur.

    Raises:
        HTTPException: Erreur 401 si les identifiants sont invalides.
    """
    client_ip = request_info.client.host if request_info.client else "unknown"
    rate_limit_key = f"{request.courriel}_{client_ip}"
    check_rate_limit(rate_limit_key)
    
    try:
        user, tokens = await authenticate_user(db, request.courriel, request.mot_de_passe)
        clear_attempts(rate_limit_key)
    except AuthenticationError as e:
        record_failed_attempt(rate_limit_key)
        await asyncio.sleep(1)  # Délai anti-timing attack
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
    """
    Génère une nouvelle paire de tokens à l'aide d'un Refresh Token valide.

    Args:
        request (TokenRefreshRequest): Le refresh token de l'utilisateur.
        db (AsyncSession): Session de la base de données.

    Returns:
        AuthResponse: Les nouveaux jetons d'authentification.

    Raises:
        HTTPException: Erreur 401 si le token est invalide ou expiré.
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

    Endpoint de vérification d'authentification.

    Args:
        current_user (User): L'utilisateur injecté par le middleware JWT.

    Returns:
        UserResponse: Les informations de l'utilisateur.
    """
    return UserResponse.model_validate(current_user)


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Supprime définitivement le compte utilisateur.

    Détruit le compte ainsi que toutes les entités en cascade (sessions, 
    feedbacks, etc.).

    Args:
        current_user (User): L'utilisateur demandant la suppression.
        db (AsyncSession): Session de la base de données.
    """
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
    """
    Initie le processus de récupération de mot de passe.

    Envoie un code par email si le compte existe. Protège contre l'énumération
    d'emails en renvoyant toujours une réponse positive générique.

    Args:
        request (ForgotPasswordRequest): L'email de récupération.
        background_tasks (BackgroundTasks): Tâches d'arrière-plan pour l'envoi d'email.
        request_info (Request): Les données de la requête pour le rate-limiting.
        db (AsyncSession): Session de la base de données.

    Returns:
        dict: Un message générique de succès.
    """
    client_ip = request_info.client.host if request_info.client else "unknown"
    rate_limit_key = f"forgot_{client_ip}"
    check_rate_limit(rate_limit_key)
    
    result = await send_password_reset_code_if_user_exists(db, request.courriel, background_tasks)
    
    # Ne pas révéler l'existence du compte
    if not result.get("sent"):
        record_failed_attempt(rate_limit_key)
        await asyncio.sleep(0.5)  # Anti-timing
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
    """
    Vérifie si le code de réinitialisation fourni est valide.

    Args:
        request (VerifyResetCodeRequest): L'email et le code à vérifier.
        db (AsyncSession): Session de la base de données.

    Returns:
        dict: Confirmation de la validité.

    Raises:
        HTTPException: Erreur 400 si le code est expiré ou incorrect.
    """
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
    """
    Réinitialise le mot de passe après vérification du code.

    Args:
        request (ResetPasswordRequest): Email, code valide et nouveau mot de passe.
        db (AsyncSession): Session de la base de données.

    Returns:
        dict: Message de succès.

    Raises:
        HTTPException: Erreur 400 si le code n'est plus valide à ce stade.
    """
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
