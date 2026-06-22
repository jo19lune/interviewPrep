"""
Router pour les exercices.

Ce module gère la récupération du catalogue d'exercices, le filtrage, 
la sélection aléatoire et la génération dynamique d'exercices à l'aide 
de l'Intelligence Artificielle.
"""

import random
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.config.settings import settings
from app.core.enums import Domaine, Niveau
from app.core.security import get_current_user
from app.core.validators import normalize_enum_filter
from app.data.database import get_db
from app.models.exercice import Exercice
from app.models.user import User
from app.schemas.exercice import ExerciceCreateRequest, ExerciceResponse, ExerciceGenerateRequest
from app.services.ai_service import AIService

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

    Prend en charge la pagination et le filtrage optionnel par domaine,
    niveau de difficulté et mots-clés (tags).

    Args:
        domaine (str | None): Filtre sur la catégorie métier.
        difficulte (str | None): Filtre sur le niveau de difficulté.
        tags (str | None): Tags séparés par des virgules pour la recherche.
        skip (int): Nombre d'éléments à ignorer.
        limit (int): Nombre maximum d'éléments à renvoyer.
        db (AsyncSession): Session de la base de données.

    Returns:
        list[ExerciceResponse]: La liste des exercices correspondants.
    """
    domaine_norm = normalize_enum_filter(domaine, {item.value for item in Domaine}, "domaine")
    difficulte_norm = normalize_enum_filter(difficulte, {item.value for item in Niveau}, "difficulte")

    query = select(Exercice)
    if domaine_norm:
        query = query.where(Exercice.domaine == domaine_norm)
    if difficulte_norm:
        query = query.where(Exercice.difficulte == difficulte_norm)

    result = await db.execute(query)
    exercises = result.scalars().all()

    if tags:
        tag_list = [tag.strip().lower() for tag in tags.split(",") if tag.strip()]
        exercises = [
            exercise
            for exercise in exercises
            if any(
                tag in {str(item).lower() for item in (exercise.etiquettes or [])} 
                for tag in tag_list
            )
        ]

    exercises = exercises[skip : skip + limit]
    return [ExerciceResponse.from_orm(exercise) for exercise in exercises]


@router.get("/random/get", response_model=ExerciceResponse)
async def get_random_exercise(
    domaine: str | None = Query(None, description="Limiter a un domaine"),
    difficulte: str | None = Query(None, description="Limiter a une difficulte"),
    db: AsyncSession = Depends(get_db),
):
    """
    Récupère un exercice aléatoire.

    Utile pour les modes d'entraînement rapide ou l'utilisateur veut 
    se tester sans choisir spécifiquement son sujet.

    Args:
        domaine (str | None): Si fourni, restreint le tirage à ce domaine.
        difficulte (str | None): Si fourni, restreint le tirage à cette difficulté.
        db (AsyncSession): Session de la base de données.

    Returns:
        ExerciceResponse: L'exercice sélectionné aléatoirement.

    Raises:
        HTTPException: Erreur 404 si aucun exercice ne correspond aux critères.
    """
    domaine_norm = normalize_enum_filter(domaine, {item.value for item in Domaine}, "domaine")
    difficulte_norm = normalize_enum_filter(difficulte, {item.value for item in Niveau}, "difficulte")

    query = select(Exercice)
    if domaine_norm:
        query = query.where(Exercice.domaine == domaine_norm)
    if difficulte_norm:
        query = query.where(Exercice.difficulte == difficulte_norm)

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
    """
    Récupère les détails complets d'un exercice spécifique.

    Args:
        exercise_id (UUID): L'identifiant unique de l'exercice.
        db (AsyncSession): Session de la base de données.

    Returns:
        ExerciceResponse: Les informations détaillées de l'exercice.

    Raises:
        HTTPException: Erreur 404 si l'exercice n'existe pas.
    """
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
    """
    Crée manuellement un nouvel exercice.

    Endpoint réservé aux contributeurs (admin/experts) pour enrichir le 
    catalogue standard.

    Args:
        request (ExerciceCreateRequest): Les données de création de l'exercice.
        current_user (User): L'utilisateur authentifié (doit avoir les droits nécessaires).
        db (AsyncSession): Session de la base de données.

    Returns:
        ExerciceResponse: L'exercice fraîchement créé.
    """
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


@router.post("/generate", response_model=ExerciceResponse, status_code=status.HTTP_201_CREATED)
async def generate_exercise(
    request: ExerciceGenerateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Génère un exercice dynamiquement grâce à l'Intelligence Artificielle.

    Fait appel au service IA configuré pour créer un scénario d'entretien sur 
    mesure en fonction du domaine, de la difficulté et d'un sujet spécifique.
    
    Args:
        request (ExerciceGenerateRequest): Les paramètres de génération.
        current_user (User): L'utilisateur authentifié.
        db (AsyncSession): Session de la base de données.

    Returns:
        ExerciceResponse: L'exercice généré par l'IA.

    Raises:
        HTTPException: Erreur 400 si la fonctionnalité est désactivée.
    """
    if not settings.ai_feature_generate_exercises:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Dynamic exercise generation is disabled on this server",
        )

    domaine = request.domaine
    difficulte = request.difficulte
    sujet = request.sujet
    nombre_questions = request.nombreQuestions
    save = request.save

    domaine_norm = normalize_enum_filter(domaine, {item.value for item in Domaine}, "domaine")
    difficulte_norm = normalize_enum_filter(difficulte, {item.value for item in Niveau}, "difficulte")

    # On ignore le lint potentiel pour s'assurer d'utiliser les chaînes
    domaine_str = domaine_norm if domaine_norm else domaine
    difficulte_str = difficulte_norm if difficulte_norm else difficulte

    ai_service = AIService()
    generated = await ai_service.generate_exercise(
        domaine=domaine_str,
        difficulte=difficulte_str,
        sujet=sujet,
        nombre_questions=nombre_questions,
    )

    exercise = Exercice(
        titre=generated.get("titre", f"Simulation {domaine_str}"),
        description=generated.get("description"),
        domaine=domaine_str,
        difficulte=difficulte_str,
        duree_sec=int(generated.get("duree_sec") or 300),
        questions=generated.get("questions") or [],
        etiquettes=generated.get("etiquettes") or [domaine_str],
        difficulte_estimee=0,
    )

    if save:
        db.add(exercise)
        await db.commit()
        await db.refresh(exercise)
        return ExerciceResponse.from_orm(exercise)

    return ExerciceResponse.model_validate({
        "id": UUID(int=0),
        "titre": exercise.titre,
        "description": exercise.description,
        "domaine": exercise.domaine,
        "difficulte": exercise.difficulte,
        "duree_sec": exercise.duree_sec,
        "questions": exercise.questions,
        "etiquettes": exercise.etiquettes,
        "difficulte_estimee": exercise.difficulte_estimee,
        "cree_le": None,
    })
