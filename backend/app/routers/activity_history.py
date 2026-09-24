"""Routes CRUD pour l'historique des activités utilisateur."""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.data.database import get_db
from app.models.user import User
from app.schemas.activity_history import (
    ActivityHistoryCreateRequest,
    ActivityHistoryResponse,
    ActivityHistoryUpdateRequest,
)
from app.services.activity_history_service import (
    create_user_activity,
    delete_user_activity,
    ensure_activity_exists,
    get_user_activity,
    list_user_activities,
    update_user_activity,
)

router = APIRouter(prefix="/activities", tags=["activities"])


@router.get("", response_model=list[ActivityHistoryResponse])
async def list_activities(
    activity_type: str | None = Query(default=None, alias="type"),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Retourne l'historique des activités de l'utilisateur courant."""
    return [
        ActivityHistoryResponse.model_validate(activity)
        for activity in await list_user_activities(
            db,
            current_user.id,
            activity_type=activity_type,
            skip=skip,
            limit=limit,
        )
    ]


@router.post("", response_model=ActivityHistoryResponse, status_code=status.HTTP_201_CREATED)
async def create_activity(
    request: ActivityHistoryCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Crée une activité dans l'historique de l'utilisateur courant."""
    if not request.type or not request.type.strip():
        raise HTTPException(status_code=422, detail="Le type d'activité est obligatoire.")
    if not request.message or not request.message.strip():
        raise HTTPException(status_code=422, detail="Le message d'activité est obligatoire.")

    activity = await create_user_activity(
        db,
        current_user.id,
        activity_type=request.type,
        message=request.message,
        metadata=request.metadata,
    )
    return ActivityHistoryResponse.model_validate(activity)


@router.get("/{activity_id}", response_model=ActivityHistoryResponse)
async def get_activity(
    activity_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Récupère une activité précise appartenant à l'utilisateur courant."""
    activity = await get_user_activity(db, current_user.id, activity_id)
    return ActivityHistoryResponse.model_validate(ensure_activity_exists(activity))


@router.put("/{activity_id}", response_model=ActivityHistoryResponse)
async def update_activity(
    activity_id: UUID,
    request: ActivityHistoryUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Met à jour une activité appartenant à l'utilisateur courant."""
    activity = await get_user_activity(db, current_user.id, activity_id)
    activity = ensure_activity_exists(activity)

    if request.type is not None and not request.type.strip():
        raise HTTPException(status_code=422, detail="Le type d'activité est invalide.")
    if request.message is not None and not request.message.strip():
        raise HTTPException(status_code=422, detail="Le message d'activité est invalide.")

    activity = await update_user_activity(
        db,
        activity,
        activity_type=request.type,
        message=request.message,
        metadata=request.metadata,
    )
    return ActivityHistoryResponse.model_validate(activity)


@router.delete("/{activity_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_activity(
    activity_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Supprime une activité appartenant à l'utilisateur courant."""
    activity = await get_user_activity(db, current_user.id, activity_id)
    activity = ensure_activity_exists(activity)
    await delete_user_activity(db, activity)
    return None
