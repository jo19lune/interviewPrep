"""Service pour la gestion de l'historique des activités utilisateur."""

from __future__ import annotations

from typing import Any
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.activity_history import ActivityHistory


async def list_user_activities(
    db: AsyncSession,
    user_id: UUID,
    *,
    activity_type: str | None = None,
    skip: int = 0,
    limit: int = 20,
) -> list[ActivityHistory]:
    stmt = select(ActivityHistory).where(ActivityHistory.utilisateur_id == user_id)
    if activity_type is not None:
        stmt = stmt.where(ActivityHistory.type == activity_type)
    stmt = stmt.order_by(ActivityHistory.cree_le.desc()).offset(skip).limit(limit)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_user_activity(
    db: AsyncSession,
    user_id: UUID,
    activity_id: UUID,
) -> ActivityHistory | None:
    stmt = select(ActivityHistory).where(
        ActivityHistory.id == activity_id,
        ActivityHistory.utilisateur_id == user_id,
    )
    result = await db.execute(stmt)
    return result.scalars().first()


async def create_user_activity(
    db: AsyncSession,
    user_id: UUID,
    *,
    activity_type: str,
    message: str,
    metadata: dict[str, Any] | None = None,
) -> ActivityHistory:
    activity = ActivityHistory(
        utilisateur_id=user_id,
        type=activity_type.strip(),
        message=message.strip(),
        metadata_=metadata or {},
    )
    db.add(activity)
    await db.commit()
    await db.refresh(activity)
    return activity


async def update_user_activity(
    db: AsyncSession,
    activity: ActivityHistory,
    *,
    activity_type: str | None = None,
    message: str | None = None,
    metadata: dict[str, Any] | None = None,
) -> ActivityHistory:
    if activity_type is not None and activity_type.strip():
        activity.type = activity_type.strip()
    if message is not None and message.strip():
        activity.message = message.strip()
    if metadata is not None:
        activity.metadata_ = metadata
    await db.commit()
    await db.refresh(activity)
    return activity


async def delete_user_activity(db: AsyncSession, activity: ActivityHistory) -> None:
    await db.delete(activity)
    await db.commit()


def ensure_activity_exists(activity: ActivityHistory | None) -> ActivityHistory:
    if activity is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Historique d'activité introuvable.",
        )
    return activity
