"""
Router pour les exercices.

Ce module gère la récupération du catalogue d'exercices, le filtrage, 
la sélection aléatoire et la génération dynamique d'exercices à l'aide 
de l'Intelligence Artificielle.
"""

from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.data.database import get_db
from app.models.user import User
from app.schemas.exercice import ExerciceCreateRequest, ExerciceResponse, ExerciceGenerateRequest
from app.services import exercice_service

router = APIRouter(prefix="/exercises", tags=["exercises"])


@router.get("", response_model=list[ExerciceResponse])
async def list_exercises(
    domaine: str | None = Query(None, description="Filtrer par domaine"),
    difficulte: str | None = Query(None, description="Filtrer par difficulte"),
    tags: str | None = Query(None, description="Filtrer par tags (comma-separated)"),
    skip: int = Query(0, ge=0, description="Pagination: offset"),
    limit: int = Query(10, ge=1, le=100, description="Pagination: limit"),
    db: AsyncSession = Depends(get_db),
):
    """
    Récupère la liste des exercices disponibles.
    """
    exercises = await exercice_service.get_exercises_list(db, domaine, difficulte, tags, skip, limit)
    return [ExerciceResponse.from_orm(exercise) for exercise in exercises]


@router.get("/random/get", response_model=ExerciceResponse)
async def get_random_exercise(
    domaine: str | None = Query(None, description="Limiter a un domaine"),
    difficulte: str | None = Query(None, description="Limiter a une difficulte"),
    db: AsyncSession = Depends(get_db),
):
    """
    Récupère un exercice aléatoire.
    """
    exercise = await exercice_service.get_random_exercise_from_db(db, domaine, difficulte)
    return ExerciceResponse.from_orm(exercise)


@router.get("/{exercise_id}", response_model=ExerciceResponse)
async def get_exercise(
    exercise_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """
    Récupère les détails complets d'un exercice spécifique.
    """
    exercise = await exercice_service.get_exercise_by_id(db, exercise_id)
    return ExerciceResponse.from_orm(exercise)


@router.post("", response_model=ExerciceResponse, status_code=status.HTTP_201_CREATED)
async def create_exercise(
    request: ExerciceCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Crée manuellement un nouvel exercice.
    """
    exercise = await exercice_service.create_exercise_in_db(db, request)
    return ExerciceResponse.from_orm(exercise)


@router.post("/generate", response_model=ExerciceResponse, status_code=status.HTTP_201_CREATED)
async def generate_exercise(
    request: ExerciceGenerateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Génère un exercice dynamiquement grâce à l'Intelligence Artificielle.
    """
    exercise = await exercice_service.generate_exercise_via_ai(db, request)
    if isinstance(exercise, ExerciceResponse):
        return exercise
    return ExerciceResponse.from_orm(exercise)
