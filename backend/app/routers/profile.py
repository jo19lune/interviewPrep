"""
Router pour la gestion du profil utilisateur.

Ce module gère les opérations relatives au profil personnel et 
professionnel : consultation, mise à jour des données, modification 
du mot de passe et téléchargement d'avatar.
"""

import logging

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.data.database import get_db
from app.models.user import User
from app.schemas.user import (
    ChangePasswordRequest,
    UserProfileUpdate,
    UserResponse,
)
from app.services import profile_service
from app.services.storage_service import StorageServiceError

router = APIRouter(prefix="/profile", tags=["profile"])
logger = logging.getLogger(__name__)


@router.get("/me", response_model=UserResponse)
async def get_profile(current_user: User = Depends(get_current_user)):
    """
    Récupère le profil complet de l'utilisateur courant.
    """
    return UserResponse.from_orm(current_user)


@router.put("/update", response_model=UserResponse)
async def update_profile(
    request: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Met à jour partiellement ou totalement le profil utilisateur.
    """
    user = await profile_service.update_user_profile(db, current_user, request)
    return UserResponse.from_orm(user)


@router.put("/avatar", response_model=UserResponse)
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Upload et mise à jour de l'image de profil (Avatar).

    Les erreurs du fournisseur de stockage sont converties en 502/413 : sans
    ce traitement, une exception Cloudinary remontait jusqu'à l'ASGI et
    renvoyait un 500 avec une traceback complète, sans message exploitable.
    """
    try:
        await profile_service.upload_user_avatar(db, current_user, file)
    except StorageServiceError as exc:
        logger.exception("Avatar upload failed for user %s", current_user.id)
        detail = str(exc)
        if "trop volumineux" in detail:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=detail,
            ) from exc
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Le service de stockage d'images est indisponible ou a refusé le fichier.",
            headers={"X-Error-Code": "STORAGE_UNAVAILABLE"},
        ) from exc
    return UserResponse.from_orm(current_user)


@router.put("/change-password")
async def change_password(
    request: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Permet à l'utilisateur de modifier son mot de passe actuel.
    """
    await profile_service.change_user_password(db, current_user, request)
    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={"message": "Mot de passe modifié avec succès."}
    )


@router.delete("/avatar", response_model=UserResponse)
async def delete_avatar(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Supprime l'avatar actuel de l'utilisateur.
    """
    await profile_service.delete_user_avatar(db, current_user)
    return UserResponse.from_orm(current_user)
