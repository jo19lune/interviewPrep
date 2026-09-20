"""Opérations de persistance des simulations."""

from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload

from app.config.settings import settings
from app.core.time import utc_now
from app.models.ai_simulation import SimulationIA
from app.models.exercice import Exercice
from app.models.feedback import Retour
from app.models.progression import Progression
from app.models.session import Session
from app.models.user import User
from app.services.simulation_ai import generate_feedback, generate_next_question
from app.services.simulation_helpers import score_answer, session_config, user_responses


async def create_simulation_session(db, current_user, request):
    result = await db.execute(select(Exercice).where(Exercice.id == request.exercice_id))
    exercice = result.scalars().first()
    if not exercice:
        raise HTTPException(status_code=404, detail="Exercise not found")
    sujet = request.subject.strip() if request.subject else None
    session = Session(
        utilisateur_id=current_user.id, exercice_id=exercice.id,
        commence_le=utc_now(), statut="EN_COURS",
        reponses=[{"type": "system", "simulation_config": {
            "sujet": sujet, "nombre_questions": request.question_count,
            "domaine": exercice.domaine, "difficulte": exercice.difficulte,
        }}],
    )
    simulation = SimulationIA(
        modele=request.model or settings.ai_primary_model or "gpt-4o-mini", temperature=0.7
    )
    session.ia_simulation = simulation
    db.add_all([session, simulation])
    await db.commit()
    await db.refresh(session)
    await db.refresh(simulation)
    return {
        "session_id": str(session.id), "status": "started",
        "exercise_title": exercice.titre,
        "first_question": await generate_next_question(exercice, session.reponses, 0, simulation.modele),
        "subject": sujet or exercice.domaine, "question_count": request.question_count,
    }


async def process_user_answer(db, current_user, session_id: UUID, reponse: str):
    reponse = reponse.strip()
    if not reponse:
        raise HTTPException(status_code=422, detail="Answer cannot be empty")
    result = await db.execute(select(Session).options(
        selectinload(Session.ia_simulation),
        selectinload(Session.retour),
    ).where(
        (Session.id == session_id) & (Session.utilisateur_id == current_user.id)
    ))
    session = result.scalars().first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    if session.statut != "EN_COURS":
        raise HTTPException(status_code=400, detail="Session is not active")
    ex_res = await db.execute(select(Exercice).where(Exercice.id == session.exercice_id))
    exercice = ex_res.scalars().first()
    if not exercice:
        raise HTTPException(status_code=404, detail="Exercise associated with session not found")
    index = len(user_responses(session.reponses or []))
    question = (exercice.questions or [])[index] if index < len(exercice.questions or []) else None
    clarity, sentiment, tip, analysis = score_answer(question, reponse)
    responses = list(session.reponses or [])
    responses.append({"texte": reponse, "question": question.get("enonce") if question else None,
                      "timestamp": utc_now().isoformat(), "index": index,
                      "score_partiel": clarity, "sentiment": sentiment,
                      "coaching_tip": tip, "analysis": analysis})
    session.reponses = responses
    model = session.ia_simulation.modele if session.ia_simulation else None
    next_question = await generate_next_question(exercice, responses, index + 1, model)
    await db.commit()
    return {
        "status": "received",
        "answer_count": len(responses),
        "next_question": next_question,
    }


async def cancel_active_session(db, current_user, session_id):
    result = await db.execute(select(Session).where(
        (Session.id == session_id) & (Session.utilisateur_id == current_user.id)
    ))
    session = result.scalars().first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    if session.statut != "EN_COURS":
        raise HTTPException(status_code=400, detail="Only active sessions can be cancelled")
    session.statut, session.termine_le = "ANNULEE", utc_now()
    await db.commit()
    return {"session_id": str(session.id), "status": "cancelled"}


async def finish_session_and_generate_feedback(db, current_user, session_id):
    result = await db.execute(select(Session).options(
        selectinload(Session.ia_simulation),
        selectinload(Session.retour),
    ).where(
        (Session.id == session_id) & (Session.utilisateur_id == current_user.id)
    ))
    session = result.scalars().first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    if session.statut == "TERMINEE" and session.retour:
        return _feedback_response(session)
    if session.statut != "EN_COURS":
        raise HTTPException(status_code=400, detail="Session is not active")
    session.statut, session.termine_le = "TERMINEE", utc_now()
    responses = user_responses(session.reponses or [])
    scores = [
        float(r["score_partiel"])
        for r in responses
        if isinstance(r.get("score_partiel"), (int, float))
    ]
    score = float(sum(scores) / len(scores)) if scores else 75.0
    session.score = score
    ex_res = await db.execute(select(Exercice).where(Exercice.id == session.exercice_id))
    exercice = ex_res.scalars().first()
    model = session.ia_simulation.modele if session.ia_simulation else None
    data = await generate_feedback(exercice, session.reponses or [], score, model)
    existing = (await db.execute(select(Retour).where(Retour.session_id == session.id))).scalars().first()
    feedback = existing or Retour(session_id=session.id)
    feedback.score_global = data["score_global"]
    feedback.points_forts, feedback.ameliorations = data["points_forts"], data["ameliorations"]
    feedback.recommandations, feedback.genere_le = data["recommandations"], utc_now()
    prog = (await db.execute(select(Progression).where(
        Progression.utilisateur_id == current_user.id))).scalars().first()
    if prog:
        prog.total_sessions += 1
        prog.meilleur_score = max(prog.meilleur_score, score)
        prog.score_moyen = round((prog.score_moyen * (prog.total_sessions - 1) + score) / prog.total_sessions, 2)
        prog.derniere_session_le = session.termine_le
    else:
        prog = Progression(utilisateur_id=current_user.id, domaine=exercice.domaine if exercice else None,
                           total_sessions=1, score_moyen=score, meilleur_score=score,
                           serie=0, derniere_session_le=session.termine_le)
    db.add_all([session, feedback, prog])
    await db.commit()
    await db.refresh(feedback)
    return _feedback_response(session, feedback)


def _feedback_response(session, feedback=None):
    feedback = feedback or session.retour
    return {
        "session_id": str(session.id),
        "status": "finished",
        "score": session.score,
        "feedback": {
            "id": str(feedback.id),
            "session_id": str(feedback.session_id),
            "score_global": feedback.score_global,
            "points_forts": feedback.points_forts,
            "ameliorations": feedback.ameliorations,
            "recommandations": feedback.recommandations,
            "genere_le": feedback.genere_le.isoformat(),
        },
    }
