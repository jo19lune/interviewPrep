"""Router exercices - Récupération et gestion des exercices"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
import random
from uuid import UUID

from app.data.database import get_db
from app.schemas.exercice import ExerciceResponse, ExerciceCreateRequest
from app.models.exercice import Exercice
from app.models.user import User
from app.core.security import get_current_user
from app.core.enums import Domaine, Niveau

router = APIRouter(prefix="/exercises", tags=["exercises"])


@router.get("", response_model=list[ExerciceResponse])
async def list_exercises(
    domaine: str = Query(None, description="Filtrer par domaine"),
    difficulte: str = Query(None, description="Filtrer par difficulté"),
    tags: str = Query(None, description="Filtrer par tags (comma-separated)"),
    skip: int = Query(0, ge=0, description="Pagination: offset"),
    limit: int = Query(10, ge=1, le=100, description="Pagination: limit"),
    db: AsyncSession = Depends(get_db)
):
    """
    Lister les exercices avec filtres optionnels
    
    Paramètres de filtrage:
    - **domaine**: TECHNIQUE, COMPORTEMENTAL, SITUATIONNEL, ETUDE_DE_CAS, MOTIVATION
    - **difficulte**: DEBUTANT, INTERMEDIAIRE, AVANCE, EXPERT
    - **tags**: Tags séparés par des virgules
    - **skip**: Nombre d'exercices à ignorer (défaut: 0)
    - **limit**: Nombre d'exercices à retourner (défaut: 10, max: 100)
    """
    query = select(Exercice)
    
    # Appliquer les filtres
    if domaine:
        query = query.where(Exercice.domaine == domaine)
    
    if difficulte:
        query = query.where(Exercice.difficulte == difficulte)
    
    # Appliquer pagination
    query = query.offset(skip).limit(limit)
    
    result = await db.execute(query)
    exercises = result.scalars().all()
    
    # Filtrer par tags si fourni
    if tags:
        tag_list = [t.strip() for t in tags.split(",")]
        exercises = [
            e for e in exercises
            if any(tag in (e.etiquettes or []) for tag in tag_list)
        ]
    
    return [ExerciceResponse.from_orm(e) for e in exercises]


@router.get("/{exercise_id}", response_model=ExerciceResponse)
async def get_exercise(
    exercise_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Récupérer les détails d'un exercice"""
    result = await db.execute(
        select(Exercice).where(Exercice.id == exercise_id)
    )
    exercise = result.scalars().first()
    
    if not exercise:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercise not found"
        )
    
    return ExerciceResponse.from_orm(exercise)


@router.get("/random/get", response_model=ExerciceResponse)
async def get_random_exercise(
    domaine: str = Query(None, description="Limiter à un domaine"),
    difficulte: str = Query(None, description="Limiter à une difficulté"),
    db: AsyncSession = Depends(get_db)
):
    """
    Récupérer un exercice aléatoire
    
    Paramètres optionnels:
    - **domaine**: Filtrer par domaine
    - **difficulte**: Filtrer par difficulté
    """
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
            detail="No exercises found matching criteria"
        )
    
    exercise = random.choice(exercises)
    return ExerciceResponse.from_orm(exercise)


@router.post("", response_model=ExerciceResponse, status_code=status.HTTP_201_CREATED)
async def create_exercise(
    request: ExerciceCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Créer un nouvel exercice (ADMIN ONLY)
    
    Structure de questions JSONB:
    ```json
    [
      {
        "type": "qcm",
        "enonce": "Question?",
        "options": ["A", "B", "C"],
        "reponse_correcte": 0,
        "explication": "Explication..."
      }
    ]
    ```
    """
    # TODO: Implémenter vérification admin
    
    new_exercise = Exercice(
        titre=request.titre,
        description=request.description,
        domaine=request.domaine,
        difficulte=request.difficulte,
        duree_sec=request.duree_sec,
        questions=request.questions,
        etiquettes=request.etiquettes
    )
    
    db.add(new_exercise)
    await db.commit()
    await db.refresh(new_exercise)
    
    return ExerciceResponse.from_orm(new_exercise)
