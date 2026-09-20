"""Service d'authentification - JWT, Bcrypt, gestion des tokens."""

from __future__ import annotations

from typing import Tuple

import bcrypt
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, status
import uuid

from app.core.exceptions import AuthenticationError
from app.models.user import User
from app.models.token_blocklist import TokenBlocklist


from .auth_tokens import TokenResponse, create_access_token, create_refresh_token, decode_token

def hash_password(password: str) -> str:
    """Hasher un mot de passe avec bcrypt.

    bcrypt impose une limite de 72 bytes pour le mot de passe.
    On tronque avant hachage pour éviter l'erreur.
    """

    raw = password or ""
    raw_bytes = raw.encode("utf-8")

    if len(raw_bytes) > 72:
        raw_bytes = raw_bytes[:72]

    return bcrypt.hashpw(raw_bytes, bcrypt.gensalt()).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Vérifier un mot de passe contre son hash."""

    raw = (plain_password or "").encode("utf-8")
    if len(raw) > 72:
        raw = raw[:72]

    return bcrypt.checkpw(raw, hashed_password.encode("utf-8"))


async def get_user_by_id(
    session: AsyncSession, user_id: str
) -> Optional[User]:
    """Récupérer un utilisateur par ID."""

    stmt = select(User).where(User.id == uuid.UUID(user_id))
    result = await session.execute(stmt)
    return result.scalars().first()


async def get_user_by_email(
    session: AsyncSession, email: str
) -> Optional[User]:
    """Récupérer un utilisateur par email."""

    result = await session.execute(
        select(User).where(User.courriel == email.lower())
    )
    return result.scalars().first()


async def register_new_user(
    session: AsyncSession, request_data: dict
) -> Tuple[User, TokenResponse]:
    """Inscrire un nouvel utilisateur et retourner ses tokens."""
    email = request_data["courriel"]
    existing_user = await get_user_by_email(session, email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )

    try:
        new_user = User(
            courriel=email,
            mot_de_passe_hash=hash_password(request_data["mot_de_passe"]),
            prenom=request_data["prenom"],
            nom=request_data["nom"],
            est_actif=True,
        )
        session.add(new_user)
        await session.commit()
        await session.refresh(new_user)
    except IntegrityError as exc:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        ) from exc

    return await authenticate_user(
        session, email, request_data["mot_de_passe"]
    )


async def authenticate_user(
    session: AsyncSession,
    email: str,
    password: str,
) -> Tuple[User, TokenResponse]:
    """Authentifier un utilisateur et retourner ses tokens."""

    user = await get_user_by_email(session, email)

    if not user:
        raise AuthenticationError("Email or password is incorrect")

    if not user.est_actif:
        raise AuthenticationError("User account is inactive")

    if not verify_password(password, user.mot_de_passe_hash):
        raise AuthenticationError("Email or password is incorrect")

    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    return user, TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
    )


async def refresh_access_token(token: str) -> TokenResponse:
    """Rafraîchir l'access token avec un refresh token."""

    payload = decode_token(token)

    if payload.get("token_type") != "refresh":
        raise AuthenticationError("Invalid refresh token type")

    user_id = payload.get("user_id")
    if not user_id:
        raise AuthenticationError("Invalid token payload")

    return TokenResponse(
        access_token=create_access_token(user_id),
        refresh_token=create_refresh_token(user_id),
    )


async def refresh_user_tokens(
    session: AsyncSession,
    token: str,
) -> Tuple[User, TokenResponse]:
    """Valider un refresh token et retourner l'utilisateur + tokens."""

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


async def revoke_token(session: AsyncSession, token: str) -> None:
    """Ajouter un token à la blocklist pour le révoquer (déconnexion)."""
    blocked_token = TokenBlocklist(token=token)
    session.add(blocked_token)
    await session.commit()


async def is_token_revoked(session: AsyncSession, token: str) -> bool:
    """Vérifier si un token est dans la blocklist."""
    stmt = select(TokenBlocklist).where(TokenBlocklist.token == token)
    result = await session.execute(stmt)
    return result.scalars().first() is not None
