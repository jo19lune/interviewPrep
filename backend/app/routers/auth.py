"""Router d'authentification - Register, Login, Refresh, Delete"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.exc import IntegrityError

from app.data.database import get_db
from app.schemas.user import (
    UserRegisterRequest, UserLoginRequest, UserResponse, 
    TokenRefreshRequest, AuthResponse
)
from app.models.user import User
from app.services.auth_service import (
    hash_password, authenticate_user, refresh_access_token,
    get_user_by_email, get_user_by_id
)
from app.core.security import get_current_user
from app.core.exceptions import AuthenticationError, ConflictError, NotFoundError

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(request: UserRegisterRequest, db: AsyncSession = Depends(get_db)):
    """
    Créer un nouveau compte utilisateur
    
    - **courriel**: Email unique pour le compte
    - **mot_de_passe**: Minimum 8 caractères
    - **prenom** (optionnel): Prénom de l'utilisateur
    - **nom** (optionnel): Nom de l'utilisateur
    """
    # Vérifier si l'email existe déjà
    existing_user = await get_user_by_email(db, request.courriel)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered"
        )
    
    # Créer le nouvel utilisateur
    try:
        new_user = User(
            courriel=request.courriel.lower(),
            mot_de_passe_hash=hash_password(request.mot_de_passe),
            prenom=request.prenom,
            nom=request.nom,
            est_actif=True
        )
        db.add(new_user)
        await db.commit()
        await db.refresh(new_user)
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered"
        )
    
    # Authentifier le nouvel utilisateur
    _, tokens = await authenticate_user(db, request.courriel, request.mot_de_passe)
    
    user_response = UserResponse.from_orm(new_user)
    return AuthResponse(
        **tokens.dict(),
        user=user_response
    )


@router.post("/login", response_model=AuthResponse)
async def login(request: UserLoginRequest, db: AsyncSession = Depends(get_db)):
    """
    Authentifier un utilisateur
    
    - **courriel**: Email de l'utilisateur
    - **mot_de_passe**: Mot de passe
    
    Retourne les tokens d'accès et de rafraîchissement
    """
    try:
        user, tokens = await authenticate_user(db, request.courriel, request.mot_de_passe)
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=e.message
        )
    
    user_response = UserResponse.from_orm(user)
    return AuthResponse(
        **tokens.dict(),
        user=user_response
    )


@router.post("/refresh", response_model=AuthResponse)
async def refresh(
    request: TokenRefreshRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Rafraîchir l'access token avec un refresh token
    
    - **refresh_token**: Refresh token fourni lors de la connexion
    """
    try:
        new_tokens = await refresh_access_token(request.refresh_token)
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=e.message
        )
    
    return AuthResponse(
        **new_tokens.dict(),
        user=UserResponse(
            id="",
            courriel="",
            est_actif=True,
            cree_le=""
        )  # Le client peut récupérer les infos avec GET /auth/me
    )


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """Récupérer les informations de l'utilisateur courant"""
    return UserResponse.from_orm(current_user)


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Supprimer le compte utilisateur et TOUTES ses données (RGPD)
    
    Cette action est irréversible. Toutes les sessions, feedbacks et données
    de progression seront supprimés.
    """
    # Supprimer l'utilisateur (cascade supprimera sessions/feedbacks via relations)
    await db.delete(current_user)
    await db.commit()
    
    return None
