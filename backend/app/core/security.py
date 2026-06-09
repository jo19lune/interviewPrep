"""
Sécurité et gestion de l'authentification.

Ce module fournit les dépendances FastAPI nécessaires pour sécuriser
les endpoints, extraire les tokens JWT et vérifier les identités des
utilisateurs.
"""

import logging

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AuthenticationError
from app.data.database import get_db
from app.models.user import User
from app.services.auth_service import decode_token, get_user_by_id

logger = logging.getLogger(__name__)

# Middleware de sécurité basé sur le schéma Bearer
security = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> User:
    """
    Extrait et valide l'utilisateur courant à partir du token JWT.

    Cette dépendance FastAPI est utilisée pour protéger les routes qui 
    requièrent une authentification. Elle valide la présence du token, 
    le décode, vérifie son type et s'assure que l'utilisateur associé
    existe et est actif.

    Args:
        credentials (HTTPAuthorizationCredentials | None): Les informations 
            d'autorisation issues de l'en-tête de la requête.
        db (AsyncSession): La session de base de données courante injectée.

    Returns:
        User: L'objet utilisateur authentifié tiré de la base de données.

    Raises:
        HTTPException: Erreur 403 si aucun token n'est fourni, ou 401 si le
            token est invalide, expiré ou si le compte utilisateur n'est pas 
            disponible/actif.
    """
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authenticated",
        )

    token = credentials.credentials
    
    try:
        payload = decode_token(token)
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e.message),
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user_id = payload.get("user_id")
    token_type = payload.get("token_type")
    
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if token_type != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Récupérer l'utilisateur de la base
    user = await get_user_by_id(db, user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.est_actif:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account is inactive",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return user
