"""
Router pour les sessions de simulation avec IA.

Gère le cycle de vie complet d'un exercice d'entretien : 
initialisation de la session, soumission des réponses, génération 
et streaming de la prochaine question par l'IA, annulation et 
clôture avec génération du feedback global.
"""

import asyncio
import json
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload

from app.config.settings import settings
from app.core.security import get_current_user
from app.data.database import get_db
from app.models.exercice import Exercice
from app.models.session import Session
from app.models.user import User
from app.models.feedback import Retour
from app.schemas.session import SessionCreateRequest, SessionResponse
from app.services import simulation_service

router = APIRouter(prefix="/simulation", tags=["simulation"])


@router.get("/models")
async def list_available_models(current_user: User = Depends(get_current_user)):
    """
    Récupère la liste des modèles d'IA configurés sur le serveur.
    """
    models = settings.openai_models or []
    primary = settings.ai_primary_model or (models[0] if models else "")
    return {"models": models, "primary_model": primary}


@router.post("/start")
async def start_simulation(
    request: SessionCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Démarre une nouvelle simulation d'entretien interactive.
    """
    return await simulation_service.create_simulation_session(db, current_user, request)


class AnswerRequest(BaseModel):
    session_id: UUID
    reponse: str

@router.post("/answer")
async def submit_answer(
    request: AnswerRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Soumet une réponse utilisateur et reçoit la question suivante.
    """
    return await simulation_service.process_user_answer(db, current_user, request.session_id, request.reponse)


@router.get("/stream/{session_id}")
async def stream_ai_response(
    session_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Stream la prochaine question IA via Server-Sent Events (SSE).
    """
    result = await db.execute(
        select(Session)
        .options(selectinload(Session.ia_simulation))
        .where(
            (Session.id == session_id) & (Session.utilisateur_id == current_user.id)
        )
    )
    session = result.scalars().first()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found")

    ex_res = await db.execute(select(Exercice).where(Exercice.id == session.exercice_id))
    exercice = ex_res.scalars().first()
    if not exercice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercise associated with session not found",
        )

    reponses = session.reponses or []
    next_index = len(simulation_service.user_responses(reponses))
    model_name = session.ia_simulation.modele if session.ia_simulation else None
    question = await simulation_service.generate_next_question(exercice, reponses, next_index, model=model_name)

    async def event_generator():
        for token in simulation_service.split_stream_tokens(question):
            payload = {"session_id": str(session.id), "text": token}
            yield f"event: token\ndata: {json.dumps(payload)}\n\n"
            await asyncio.sleep(0.02)
        yield "event: done\ndata: {}\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")


@router.post("/cancel/{session_id}")
async def cancel_simulation(
    session_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Annule explicitement une simulation active.
    """
    return await simulation_service.cancel_active_session(db, current_user, session_id)


@router.post("/finish/{session_id}")
async def finish_simulation(
    session_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Termine la simulation et déclenche la génération du feedback global.
    """
    return await simulation_service.finish_session_and_generate_feedback(db, current_user, session_id)


@router.get("/sessions")
async def list_user_sessions(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Liste toutes les sessions de l'utilisateur (terminées ou non).
    """
    from app.services.stats_service import get_user_session_history
    sessions = await get_user_session_history(db, current_user.id, skip, limit)
    return [SessionResponse.from_orm(s) for s in sessions]


@router.get("/sessions/{session_id}")
async def get_session_conversation(
    session_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Récupère le détail complet d'une session : réponses, feedback, exercice.
    """
    result = await db.execute(
        select(Session)
        .options(selectinload(Session.ia_simulation), selectinload(Session.retour))
        .where(
            (Session.id == session_id) & (Session.utilisateur_id == current_user.id)
        )
    )
    session = result.scalars().first()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found")

    ex_res = await db.execute(select(Exercice).where(Exercice.id == session.exercice_id))
    exercice = ex_res.scalars().first()

    feedback_data = None
    if session.retour:
        feedback_data = {
            "id": str(session.retour.id),
            "score_global": session.retour.score_global,
            "points_forts": session.retour.points_forts or [],
            "ameliorations": session.retour.ameliorations or [],
            "recommandations": session.retour.recommandations or [],
            "genere_le": session.retour.genere_le.isoformat(),
        }

    user_responses = simulation_service.user_responses(session.reponses or [])

    return {
        "session": SessionResponse.from_orm(session).model_dump(),
        "feedback": feedback_data,
        "exercise_title": exercice.titre if exercice else None,
        "exercise_domaine": exercice.domaine if exercice else None,
        "user_responses": user_responses,
    }
