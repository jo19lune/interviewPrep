"""Router progression - Suivi statistique et historique"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func, desc
from datetime import datetime, timedelta
from uuid import UUID

from app.data.database import get_db
from app.schemas.session import SessionResponse
from app.models.user import User
from app.models.session import Session
from app.models.progression import Progression
from app.core.security import get_current_user

router = APIRouter(prefix="/progress", tags=["progress"])


class ProgressStats:
    """Statistiques de progression"""
    def __init__(self):
        self.total_sessions = 0
        self.avg_score = 0.0
        self.best_score = 0.0
        self.streak = 0
        self.last_session_date: str = None


@router.get("/me")
async def get_my_progress(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Récupérer la progression personnelle de l'utilisateur"""
    result = await db.execute(
        select(Session)
        .where(Session.utilisateur_id == current_user.id)
        .where(Session.statut == "TERMINEE")
        .order_by(desc(Session.termine_le))
    )
    sessions = result.scalars().all()
    
    if not sessions:
        return {
            "total_sessions": 0,
            "avg_score": 0.0,
            "best_score": 0.0,
            "streak": 0,
            "last_session_date": None
        }
    
    scores = [s.score for s in sessions]
    avg_score = sum(scores) / len(scores) if scores else 0.0
    best_score = max(scores) if scores else 0.0
    
    return {
        "total_sessions": len(sessions),
        "avg_score": round(avg_score, 2),
        "best_score": round(best_score, 2),
        "streak": 0,  # TODO: Implémenter calcul
        "last_session_date": sessions[0].termine_le if sessions else None
    }


@router.get("/stats")
async def get_detailed_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Récupérer statistiques détaillées par domaine"""
    result = await db.execute(
        select(Session)
        .where(Session.utilisateur_id == current_user.id)
        .where(Session.statut == "TERMINEE")
    )
    sessions = result.scalars().all()
    
    # Grouper par domaine (via l'exercice)
    domains_stats = {}
    for session in sessions:
        # TODO: Récupérer le domaine de l'exercice
        domaine = getattr(session, 'exercice', None)
        if domaine not in domains_stats:
            domains_stats[domaine] = {
                "total": 0,
                "avg_score": 0.0,
                "best_score": 0.0,
                "scores": []
            }
        domains_stats[domaine]["total"] += 1
        domains_stats[domaine]["scores"].append(session.score)
    
    # Calculer moyennes
    for domain, stats in domains_stats.items():
        if stats["scores"]:
            stats["avg_score"] = round(sum(stats["scores"]) / len(stats["scores"]), 2)
            stats["best_score"] = round(max(stats["scores"]), 2)
        del stats["scores"]
    
    return domains_stats


@router.get("/history")
async def get_session_history(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Récupérer l'historique des sessions de l'utilisateur"""
    result = await db.execute(
        select(Session)
        .where(Session.utilisateur_id == current_user.id)
        .order_by(desc(Session.commence_le))
        .offset(skip)
        .limit(limit)
    )
    sessions = result.scalars().all()
    
    return [SessionResponse.from_orm(s) for s in sessions]


@router.get("/export")
async def export_progress_pdf(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Exporter rapport PDF de progression"""
    # TODO: Implémenter génération PDF
    return {
        "message": "PDF export not yet implemented",
        "url": None
    }
