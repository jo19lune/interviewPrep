"""
Service pour le calcul des statistiques de progression.
"""

from datetime import timedelta
from typing import Any

from sqlalchemy import desc
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.models.exercice import Exercice
from app.models.session import Session
from app.core.time import utc_now


async def get_user_progress_stats(db: AsyncSession, user_id: str) -> dict[str, Any]:
    result = await db.execute(
        select(Session)
        .where(Session.utilisateur_id == user_id)
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
    cursor = utc_now().date()
    
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


async def get_user_detailed_stats(db: AsyncSession, user_id: str) -> dict[str, dict[str, Any]]:
    result = await db.execute(
        select(Session, Exercice)
        .join(Exercice, Session.exercice_id == Exercice.id)
        .where(Session.utilisateur_id == user_id)
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


async def get_user_session_history(db: AsyncSession, user_id: str, skip: int, limit: int):
    result = await db.execute(
        select(Session)
        .where(Session.utilisateur_id == user_id)
        .order_by(desc(Session.commence_le))
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()
