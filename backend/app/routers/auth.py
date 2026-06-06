"""Router d'authentification - register, login, refresh, delete."""

from fastapi import APIRouter, Depends, HTTPException, status
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


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(request: UserRegisterRequest, db: AsyncSession = Depends(get_db)):
    """Creer un nouveau compte utilisateur."""
    email = request.courriel.lower()
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
async def login(request: UserLoginRequest, db: AsyncSession = Depends(get_db)):
    """Authentifier un utilisateur."""
    try:
        user, tokens = await authenticate_user(db, request.courriel, request.mot_de_passe)
    except AuthenticationError as e:
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
    """Supprimer le compte utilisateur et ses donnees liees."""
    await db.delete(current_user)
    await db.commit()
    return None
