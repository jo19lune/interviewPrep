"""
Router pour la gestion du profil utilisateur.

Ce module gère les opérations relatives au profil personnel et 
professionnel : consultation, mise à jour des données, modification 
du mot de passe et téléchargement d'avatar.
"""

import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from starlette.concurrency import run_in_threadpool

from app.config.settings import settings
from app.core.enums import Domaine, Niveau
from app.core.security import get_current_user
from app.data.database import get_db
from app.models.user import User
from app.schemas.user import ChangePasswordRequest, UserProfileUpdate, UserResponse
from app.services.auth_service import hash_password, verify_password

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("/me", response_model=UserResponse)
async def get_profile(current_user: User = Depends(get_current_user)):
    """
    Récupère le profil complet de l'utilisateur courant.

    Fournit les informations du compte, y compris le nom, l'avatar,
    le niveau et le domaine professionnel.

    Args:
        current_user (User): L'utilisateur authentifié (injecté via JWT).

    Returns:
        UserResponse: Les données publiques de l'utilisateur sérialisées.
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
    
    Permet à l'utilisateur de modifier son identité et ses préférences
    professionnelles.
    
    Args:
        request (UserProfileUpdate): Les nouveaux champs du profil (optionnels).
            - prenom: Prénom
            - nom: Nom de famille
            - domaine: Domaine professionnel (ex: TECHNIQUE)
            - niveau: Niveau d'expertise (ex: DEBUTANT)
        current_user (User): L'utilisateur courant authentifié.
        db (AsyncSession): La session de base de données.

    Returns:
        UserResponse: L'objet utilisateur avec les données mises à jour.

    Raises:
        HTTPException: Erreur 422 si le domaine ou le niveau fourni n'est pas 
        une valeur valide des énumérations.
    """
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


def _save_upload_file(upload_dir: str, upload_file: UploadFile) -> str:
    """
    Fonction utilitaire synchrone pour enregistrer un fichier uploadé.

    Génère un nom de fichier unique basé sur un UUID tout en conservant 
    l'extension originale, puis le sauvegarde sur le disque.

    Args:
        upload_dir (str): Le chemin absolu ou relatif vers le dossier d'uploads.
        upload_file (UploadFile): L'objet fichier venant de la requête FastAPI.

    Returns:
        str: Le chemin d'accès complet au fichier enregistré.
    """
    upload_path = Path(upload_dir)
    upload_path.mkdir(parents=True, exist_ok=True)
    
    file_extension = Path(upload_file.filename or "avatar.png").suffix or ".png"
    unique_name = f"{uuid.uuid4().hex}{file_extension}"
    file_path = upload_path / unique_name
    
    with open(file_path, "wb") as buffer:
        buffer.write(upload_file.file.read())
    
    return str(file_path)


@router.put("/avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Upload et mise à jour de l'image de profil (Avatar).
    
    Vérifie le format du fichier, sa taille (max 5MB) et le sauvegarde 
    localement. L'URL publique de l'avatar est ensuite rattachée au profil.

    Args:
        file (UploadFile): Le fichier binaire transmis via form-data.
        current_user (User): L'utilisateur courant authentifié.
        db (AsyncSession): La session de base de données.

    Returns:
        JSONResponse: Un message de confirmation accompagné de l'URL de l'avatar.

    Raises:
        HTTPException: Erreur 415 si le format n'est pas supporté, ou 413 si 
        la taille dépasse la limite autorisée.
    """
    allowed_types = {'image/jpeg', 'image/png', 'image/gif', 'image/webp'}
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported file type: {file.content_type}. Allowed: {allowed_types}",
        )
    
    max_size = 5 * 1024 * 1024
    content = await file.read()
    if len(content) > max_size:
        raise HTTPException(
            status_code=status.HTTP_413_PAYLOAD_TOO_LARGE,
            detail="File size exceeds 5MB limit",
        )
    
    await file.seek(0)
    
    upload_dir = settings.upload_dir
    saved_path = await run_in_threadpool(_save_upload_file, upload_dir, file)
    
    base_url = (settings.upload_base_url or "").rstrip("/")
    if base_url:
        avatar_url = f"{base_url}/static/{Path(saved_path).name}"
    else:
        avatar_url = f"/static/{Path(saved_path).name}"
    
    current_user.avatar_url = avatar_url
    db.add(current_user)
    await db.commit()
    await db.refresh(current_user)
    
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
    
    L'utilisateur doit fournir son ancien mot de passe, qui sera vérifié,
    avant que le nouveau mot de passe (qui doit être différent) ne soit 
    haché et sauvegardé.

    Args:
        request (ChangePasswordRequest): Le payload avec l'ancien et le nouveau mot de passe.
        current_user (User): L'utilisateur courant authentifié.
        db (AsyncSession): La session de base de données.

    Returns:
        JSONResponse: Un message de confirmation de succès.

    Raises:
        HTTPException: Erreur 400 si l'ancien mot de passe est faux ou si
        le nouveau est identique à l'ancien.
    """
    if not verify_password(request.mot_de_passe_actuel, current_user.mot_de_passe_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le mot de passe actuel est incorrect."
        )
    
    if request.mot_de_passe_actuel == request.nouveau_mot_de_passe:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le nouveau mot de passe doit être différent de l'ancien."
        )
        
    current_user.mot_de_passe_hash = hash_password(request.nouveau_mot_de_passe)
    
    db.add(current_user)
    await db.commit()
    
    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={"message": "Mot de passe modifié avec succès."}
    )
