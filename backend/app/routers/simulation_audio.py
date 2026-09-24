"""Endpoint de réponse audio pour les simulations."""

import os
import tempfile
from uuid import UUID

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.settings import settings
from app.core.security import get_current_user
from app.data.database import get_db
from app.models.user import User
from app.services.ai_service import AIService
from app.services import simulation_service

router = APIRouter(prefix="/simulation", tags=["simulation"])


@router.post("/answer/audio")
async def submit_audio_answer(
    session_id: UUID,
    audio: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not audio.content_type or not audio.content_type.startswith("audio/"):
        raise HTTPException(status_code=400, detail="Fichier non valide. Audio requis.")
    suffix = os.path.splitext(audio.filename or ".m4a")[1] or ".m4a"
    fd, path = tempfile.mkstemp(prefix=f"{session_id}_", suffix=suffix)
    os.close(fd)
    try:
        with open(path, "wb") as buffer:
            while chunk := await audio.read(1024 * 1024):
                buffer.write(chunk)
        if not settings.ai_feature_transcribe_audio:
            raise HTTPException(status_code=503, detail="Transcription audio désactivée sur ce serveur.")
        text = await AIService().transcribe_audio(path)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Erreur lors du traitement audio.") from exc
    finally:
        try:
            os.remove(path)
        except FileNotFoundError:
            pass
    return await simulation_service.process_user_answer(db, current_user, session_id, text)
