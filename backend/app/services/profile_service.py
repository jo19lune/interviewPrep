from pathlib import Path
from fastapi import HTTPException, status, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from starlette.concurrency import run_in_threadpool

from app.config.settings import settings
from app.core.enums import Domaine, Niveau
from app.models.user import User
from app.schemas.user import ChangePasswordRequest, UserProfileUpdate
from app.services.auth_service import hash_password, verify_password
from app.utils.file_utils import save_upload_file


async def update_user_profile(db: AsyncSession, current_user: User, request: UserProfileUpdate) -> User:
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
    
    return current_user


async def change_user_password(db: AsyncSession, current_user: User, request: ChangePasswordRequest) -> None:
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


async def upload_user_avatar(db: AsyncSession, current_user: User, file: UploadFile) -> str:
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
    saved_path = await run_in_threadpool(save_upload_file, upload_dir, file)
    
    base_url = (settings.upload_base_url or "").rstrip("/")
    if base_url:
        avatar_url = f"{base_url}/static/{Path(saved_path).name}"
    else:
        avatar_url = f"/static/{Path(saved_path).name}"
    
    current_user.avatar_url = avatar_url
    db.add(current_user)
    await db.commit()
    await db.refresh(current_user)
    
    return avatar_url
