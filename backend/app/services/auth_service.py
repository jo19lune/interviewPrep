"""Service d'authentification - JWT, Bcrypt, gestion des tokens"""

from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel

from app.config.settings import settings
from app.models.user import User
from app.core.exceptions import AuthenticationError, ValidationError

# Configuration Bcrypt
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class TokenResponse(BaseModel):
    """Réponse de token"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    """Données contenues dans le token JWT"""
    user_id: str
    exp: datetime
    token_type: str  # "access" ou "refresh"


def hash_password(password: str) -> str:
    """Hasher un mot de passe avec Bcrypt"""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Vérifier un mot de passe contre son hash"""
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(user_id: str, expires_delta: Optional[timedelta] = None) -> str:
    """Créer un access token JWT"""
    if expires_delta is None:
        expires_delta = timedelta(minutes=settings.access_token_expire_minutes)
    
    expire = datetime.now(timezone.utc) + expires_delta
    data = {
        "user_id": str(user_id),
        "exp": expire,
        "token_type": "access"
    }
    
    token = jwt.encode(data, settings.secret_key, algorithm=settings.algorithm)
    return token


def create_refresh_token(user_id: str, expires_delta: Optional[timedelta] = None) -> str:
    """Créer un refresh token JWT"""
    if expires_delta is None:
        expires_delta = timedelta(minutes=settings.refresh_token_expire_minutes)
    
    expire = datetime.now(timezone.utc) + expires_delta
    data = {
        "user_id": str(user_id),
        "exp": expire,
        "token_type": "refresh"
    }
    
    token = jwt.encode(data, settings.secret_key, algorithm=settings.algorithm)
    return token


def decode_token(token: str) -> dict:
    """Décoder et valider un token JWT"""
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        return payload
    except JWTError as e:
        raise AuthenticationError(f"Invalid token: {e}")


async def get_user_by_id(session: AsyncSession, user_id: str) -> Optional[User]:
    """Récupérer un utilisateur par ID"""
    from uuid import UUID
    result = await session.execute(select(User).where(User.id == UUID(user_id)))
    return result.scalars().first()


async def get_user_by_email(session: AsyncSession, email: str) -> Optional[User]:
    """Récupérer un utilisateur par email"""
    result = await session.execute(select(User).where(User.courriel == email.lower()))
    return result.scalars().first()


async def authenticate_user(
    session: AsyncSession,
    email: str,
    password: str
) -> Tuple[User, TokenResponse]:
    """Authentifier un utilisateur et retourner ses tokens"""
    user = await get_user_by_email(session, email)
    
    if not user:
        raise AuthenticationError("Email or password is incorrect")
    
    if not user.est_actif:
        raise AuthenticationError("User account is inactive")
    
    if not verify_password(password, user.mot_de_passe_hash):
        raise AuthenticationError("Email or password is incorrect")
    
    # Générer les tokens
    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))
    
    tokens = TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token
    )
    
    return user, tokens


async def refresh_access_token(token: str) -> TokenResponse:
    """Rafraîchir l'access token avec un refresh token"""
    payload = decode_token(token)
    
    if payload.get("token_type") != "refresh":
        raise AuthenticationError("Invalid refresh token type")
    
    user_id = payload.get("user_id")
    if not user_id:
        raise AuthenticationError("Invalid token payload")
    
    new_access_token = create_access_token(user_id)
    new_refresh_token = create_refresh_token(user_id)
    
    return TokenResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token
    )


async def refresh_user_tokens(session: AsyncSession, token: str) -> Tuple[User, TokenResponse]:
    """Valider un refresh token et retourner l'utilisateur avec une nouvelle paire de tokens."""
    payload = decode_token(token)

    if payload.get("token_type") != "refresh":
        raise AuthenticationError("Invalid refresh token type")

    user_id = payload.get("user_id")
    if not user_id:
        raise AuthenticationError("Invalid token payload")

    user = await get_user_by_id(session, user_id)
    if not user:
        raise AuthenticationError("User not found")
    if not user.est_actif:
        raise AuthenticationError("User account is inactive")

    return user, TokenResponse(
        access_token=create_access_token(user_id),
        refresh_token=create_refresh_token(user_id),
    )
