"""
Router pour la gestion du profil utilisateur.

Ce module gère les opérations relatives au profil personnel et 
professionnel : consultation, mise à jour des données, modification 
du mot de passe et téléchargement d'avatar.
"""

from fastapi import APIRouter, Depends, File, UploadFile, status
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.data.database import get_db
from app.models.user import User
from app.schemas.user import ChangePasswordRequest, UserProfileUpdate, UserResponse
from app.services import profile_service

router = APIRouter(prefix="/profile", tags=["profile"])


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


@router.put("/avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Upload et mise à jour de l'image de profil (Avatar).
    """
    avatar_url = await profile_service.upload_user_avatar(db, current_user, file)
    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={
            "message": "Avatar uploadé avec succès",
            "avatar_url": avatar_url,
        },
    )


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
