"""Router profil - Récupération et mise à jour des informations utilisateur"""

import os
import uuid
from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from starlette.concurrency import run_in_threadpool

from app.data.database import get_db
from app.schemas.user import UserResponse, UserProfileUpdate
from app.models.user import User
from app.core.security import get_current_user
from app.core.enums import Domaine, Niveau
from app.config.settings import settings

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
    Uploader une image de profil.
    
    - Accepte les formats image courants (jpeg, png, gif, webp)
    - Limite de taille: 5MB
    - Le fichier est stocké localement selon UPLOAD_DIR
    - Retourne l'URL publique de l'avatar via UPLOAD_BASE_URL
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
    avatar_url = f"{base_url}/static/{Path(saved_path).name}" if base_url else f"/static/{Path(saved_path).name}"
    
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
