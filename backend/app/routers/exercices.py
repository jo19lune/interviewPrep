"""Router exercices - Recuperation et gestion des exercices."""

import random
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.core.enums import Domaine, Niveau
from app.core.security import get_current_user
from app.data.database import get_db
from app.models.exercice import Exercice
from app.models.user import User
from app.schemas.exercice import ExerciceCreateRequest, ExerciceResponse

router = APIRouter(prefix="/exercises", tags=["exercises"])


@router.get("", response_model=list[ExerciceResponse])
async def list_exercises(
    domaine: str = Query(None, description="Filtrer par domaine"),
    difficulte: str = Query(None, description="Filtrer par difficulte"),
    tags: str = Query(None, description="Filtrer par tags (comma-separated)"),
    skip: int = Query(0, ge=0, description="Pagination: offset"),
    limit: int = Query(10, ge=1, le=100, description="Pagination: limit"),
    db: AsyncSession = Depends(get_db),
):
    """Lister les exercices avec filtres optionnels."""
    domaine = _normalize_enum_filter(domaine, {item.value for item in Domaine}, "domaine")
    difficulte = _normalize_enum_filter(difficulte, {item.value for item in Niveau}, "difficulte")

    query = select(Exercice)
    if domaine:
        query = query.where(Exercice.domaine == domaine)
    if difficulte:
        query = query.where(Exercice.difficulte == difficulte)

    result = await db.execute(query)
    exercises = result.scalars().all()

    if tags:
        tag_list = [tag.strip().lower() for tag in tags.split(",") if tag.strip()]
        exercises = [
            exercise
            for exercise in exercises
            if any(tag in {str(item).lower() for item in (exercise.etiquettes or [])} for tag in tag_list)
        ]

    exercises = exercises[skip : skip + limit]
    return [ExerciceResponse.from_orm(exercise) for exercise in exercises]


@router.get("/random/get", response_model=ExerciceResponse)
async def get_random_exercise(
    domaine: str = Query(None, description="Limiter a un domaine"),
    difficulte: str = Query(None, description="Limiter a une difficulte"),
    db: AsyncSession = Depends(get_db),
):
    """Recuperer un exercice aleatoire."""
    domaine = _normalize_enum_filter(domaine, {item.value for item in Domaine}, "domaine")
    difficulte = _normalize_enum_filter(difficulte, {item.value for item in Niveau}, "difficulte")

    query = select(Exercice)
    if domaine:
        query = query.where(Exercice.domaine == domaine)
    if difficulte:
        query = query.where(Exercice.difficulte == difficulte)

    result = await db.execute(query)
    exercises = result.scalars().all()

    if not exercises:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No exercises found matching criteria",
        )

    return ExerciceResponse.from_orm(random.choice(exercises))


@router.get("/{exercise_id}", response_model=ExerciceResponse)
async def get_exercise(
    exercise_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """Recuperer les details d'un exercice."""
    result = await db.execute(select(Exercice).where(Exercice.id == exercise_id))
    exercise = result.scalars().first()

    if not exercise:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercise not found",
        )

    return ExerciceResponse.from_orm(exercise)


@router.post("", response_model=ExerciceResponse, status_code=status.HTTP_201_CREATED)
async def create_exercise(
    request: ExerciceCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Creer un nouvel exercice."""
    new_exercise = Exercice(
        titre=request.titre,
        description=request.description,
        domaine=request.domaine,
        difficulte=request.difficulte,
        duree_sec=request.duree_sec,
        questions=request.questions,
        etiquettes=request.etiquettes,
    )

    db.add(new_exercise)
    await db.commit()
    await db.refresh(new_exercise)

    return ExerciceResponse.from_orm(new_exercise)


def _normalize_enum_filter(value: str | None, allowed: set[str], field_name: str) -> str | None:
    if value is None:
        return None

    normalized = value.strip().upper()
    if not normalized:
        return None
    if normalized not in allowed:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"{field_name} must be one of: {', '.join(sorted(allowed))}",
        )
    return normalized
