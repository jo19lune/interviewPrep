"""Service des exercices."""

import random
from datetime import datetime
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.config.settings import settings
from app.core.enums import Domaine, Niveau
from app.core.validators import normalize_enum_filter
from app.models.exercice import Exercice
from app.schemas.exercice import ExerciceCreateRequest, ExerciceGenerateRequest, ExerciceResponse
from app.services.ai_service import AIService


async def get_exercises_list(db: AsyncSession, domaine: str | None, difficulte: str | None, tags: str | None, skip: int, limit: int):
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
    return exercises


async def get_random_exercise_from_db(db: AsyncSession, domaine: str | None, difficulte: str | None):
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

    return random.choice(exercises)


async def get_exercise_by_id(db: AsyncSession, exercise_id: UUID):
    result = await db.execute(select(Exercice).where(Exercice.id == exercise_id))
    exercise = result.scalars().first()

    if not exercise:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercise not found",
        )

    return exercise


async def create_exercise_in_db(db: AsyncSession, request: ExerciceCreateRequest):
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

    return new_exercise


async def generate_exercise_via_ai(db: AsyncSession, request: ExerciceGenerateRequest):
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
        difficulte_estimee=int(generated.get("difficulte_estimee") or 0),
    )

    if save:
        db.add(exercise)
        await db.commit()
        await db.refresh(exercise)
        return exercise

    return ExerciceResponse(
        id=UUID(int=0),
        titre=exercise.titre,
        description=exercise.description,
        domaine=exercise.domaine,
        difficulte=exercise.difficulte,
        duree_sec=exercise.duree_sec,
        questions=exercise.questions,
        etiquettes=exercise.etiquettes,
        difficulte_estimee=exercise.difficulte_estimee or 0,
        cree_le=datetime.utcnow(),
    )
