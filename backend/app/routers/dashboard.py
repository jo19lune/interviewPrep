"""Router progression - Suivi statistique et historique."""

from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, Query
from sqlalchemy import desc
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.core.security import get_current_user
from app.data.database import get_db
from app.models.exercice import Exercice
from app.models.session import Session
from app.models.user import User
from app.schemas.session import SessionResponse

router = APIRouter(prefix="/progress", tags=["progress"])


@router.get("/me")
async def get_my_progress(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Recuperer la progression personnelle de l'utilisateur."""
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
            "last_session_date": None,
        }

    scores = [s.score for s in sessions if s.score is not None]
    avg_score = sum(scores) / len(scores) if scores else 0.0
    best_score = max(scores) if scores else 0.0

    completed_dates = {
        s.termine_le.date()
        for s in sessions
        if s.termine_le is not None
    }
    streak = 0
    cursor = datetime.utcnow().date()
    if cursor not in completed_dates:
        cursor = cursor - timedelta(days=1)
    while cursor in completed_dates:
        streak += 1
        cursor = cursor - timedelta(days=1)

    return {
        "total_sessions": len(sessions),
        "avg_score": round(avg_score, 2),
        "best_score": round(best_score, 2),
        "streak": streak,
        "last_session_date": sessions[0].termine_le,
    }


@router.get("/stats")
async def get_detailed_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Recuperer les statistiques detaillees par domaine."""
    result = await db.execute(
        select(Session, Exercice)
        .join(Exercice, Session.exercice_id == Exercice.id)
        .where(Session.utilisateur_id == current_user.id)
        .where(Session.statut == "TERMINEE")
    )
    rows = result.all()

    domains_stats = {}
    for session, exercice in rows:
        domaine = exercice.domaine
        if domaine not in domains_stats:
            domains_stats[domaine] = {
                "total": 0,
                "avg_score": 0.0,
                "best_score": 0.0,
                "scores": [],
            }
        domains_stats[domaine]["total"] += 1
        if session.score is not None:
            domains_stats[domaine]["scores"].append(session.score)

    for stats in domains_stats.values():
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
    db: AsyncSession = Depends(get_db),
):
    """Recuperer l'historique des sessions de l'utilisateur."""
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
    db: AsyncSession = Depends(get_db),
):
    """Exporter le rapport PDF de progression."""
    return {
        "message": "PDF export not yet implemented",
        "url": None,
    }
