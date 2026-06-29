"""
Router pour la progression et le suivi statistique.

Ce module définit les endpoints permettant à un utilisateur de
consulter ses statistiques d'entraînement, son historique de 
sessions d'entretiens et son tableau de bord personnel.
"""

from typing import Any

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.data.database import get_db
from app.models.user import User
from app.schemas.session import SessionResponse
from app.services import stats_service

router = APIRouter(prefix="/progress", tags=["progress"])


@router.get("/me")
async def get_my_progress(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict[str, Any]:
    """
    Récupère la progression personnelle globale de l'utilisateur courant.
    """
    return await stats_service.get_user_progress_stats(db, current_user.id)


@router.get("/stats")
async def get_detailed_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict[str, dict[str, Any]]:
    """
    Récupère les statistiques détaillées regroupées par domaine.
    """
    return await stats_service.get_user_detailed_stats(db, current_user.id)


@router.get("/history", response_model=list[SessionResponse])
async def get_session_history(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Récupère l'historique paginé des sessions de l'utilisateur.
    """
    sessions = await stats_service.get_user_session_history(db, current_user.id, skip, limit)
    return [SessionResponse.from_orm(s) for s in sessions]


@router.get("/export")
async def export_progress_pdf(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict[str, Any]:
    """
    Exporte le rapport de progression au format PDF.
    """
    return {
        "message": "PDF export not yet implemented",
        "url": None,
    }
