"""Router profil - Récupération et mise à jour des informations utilisateur"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.data.database import get_db
from app.schemas.user import UserResponse, UserProfileUpdate
from app.models.user import User
from app.core.security import get_current_user
from app.core.enums import Domaine, Niveau

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("/me", response_model=UserResponse)
async def get_profile(current_user: User = Depends(get_current_user)):
    """Récupérer le profil complet de l'utilisateur courant"""
    return UserResponse.from_orm(current_user)


@router.put("/update", response_model=UserResponse)
async def update_profile(
    request: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Mettre à jour le profil utilisateur
    
    - **prenom** (optionnel): Prénom
    - **nom** (optionnel): Nom
    - **domaine** (optionnel): Domaine cible (TECHNIQUE, COMPORTEMENTAL, etc.)
    - **niveau** (optionnel): Niveau cible (DEBUTANT, INTERMEDIAIRE, AVANCE, EXPERT)
    """
    # Valider les énums si fournis
    if request.domaine:
        try:
            Domaine(request.domaine)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Invalid domaine. Must be one of: {[d.value for d in Domaine]}"
            )
    
    if request.niveau:
        try:
            Niveau(request.niveau)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Invalid niveau. Must be one of: {[n.value for n in Niveau]}"
            )
    
    # Mettre à jour les champs fournis
    if request.prenom is not None:
        current_user.prenom = request.prenom
    if request.nom is not None:
        current_user.nom = request.nom
    if request.domaine is not None:
        current_user.domaine = request.domaine
    if request.niveau is not None:
        current_user.niveau = request.niveau
    
    db.add(current_user)
    await db.commit()
    await db.refresh(current_user)
    
    return UserResponse.from_orm(current_user)


@router.put("/avatar")
async def upload_avatar(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Uploader une image de profil
    
    Note: Endpoint à implémenter avec support multipart/form-data
    pour l'upload de fichier image
    """
    # TODO: Implémenter upload de fichier
    return {"message": "Avatar upload not yet implemented"}
