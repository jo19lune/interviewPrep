"""Router simulation IA - Gestion des sessions de simulation avec IA."""

import asyncio
import json
from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.config.settings import settings
from app.core.security import get_current_user
from app.data.database import get_db
from app.models.ai_simulation import SimulationIA
from app.models.exercice import Exercice
from app.models.feedback import Retour
from app.models.session import Session
from app.models.user import User
from app.services.ai_service import AIService

router = APIRouter(prefix="/simulation", tags=["simulation"])


@router.post("/start")
async def start_simulation(
    exercice_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Demarrer une nouvelle simulation IA."""
    result = await db.execute(select(Exercice).where(Exercice.id == exercice_id))
    exercice = result.scalars().first()

    if not exercice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercise not found",
        )

    session = Session(
        utilisateur_id=current_user.id,
        exercice_id=exercice_id,
        commence_le=datetime.utcnow(),
        statut="EN_COURS",
        reponses=[],
    )
    ia_sim = SimulationIA(
        modele="claude-3-5-sonnet-20241022",
        temperature=0.7,
    )
    session.ia_simulation = ia_sim

    db.add(session)
    db.add(ia_sim)
    await db.commit()
    await db.refresh(session)

    return {
        "session_id": str(session.id),
        "status": "started",
        "exercise_title": exercice.titre,
        "first_question": _fallback_question(exercice, 0, []),
    }


@router.post("/answer")
async def submit_answer(
    session_id: UUID,
    reponse: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Soumettre une reponse et recevoir la question suivante."""
    reponse = reponse.strip()
    if not reponse:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Answer cannot be empty",
        )

    result = await db.execute(
        select(Session).where(
            (Session.id == session_id) & (Session.utilisateur_id == current_user.id)
        )
    )
    session = result.scalars().first()

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )
    if session.statut != "EN_COURS":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Session is not active",
        )

    ex_res = await db.execute(select(Exercice).where(Exercice.id == session.exercice_id))
    exercice = ex_res.scalars().first()
    if not exercice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercise associated with session not found",
        )

    current_q_index = len(session.reponses or [])
    questions = exercice.questions or []
    clarity_score, sentiment, coaching_tip = _score_answer(
        questions[current_q_index] if current_q_index < len(questions) else None,
        reponse,
    )

    updated_reponses = list(session.reponses or [])
    updated_reponses.append(
        {
            "texte": reponse,
            "timestamp": datetime.utcnow().isoformat(),
            "index": current_q_index,
            "score_partiel": clarity_score,
            "sentiment": sentiment,
            "coaching_tip": coaching_tip,
        }
    )
    session.reponses = updated_reponses

    next_question = await _generate_next_question(exercice, updated_reponses, current_q_index + 1)

    db.add(session)
    await db.commit()
    await db.refresh(session)

    return {
        "status": "received",
        "answer_count": len(session.reponses or []),
        "clarity_score": clarity_score,
        "sentiment": sentiment,
        "coaching_tip": coaching_tip,
        "next_question": next_question,
    }


@router.get("/stream/{session_id}")
async def stream_ai_response(
    session_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Streamer la prochaine question IA en SSE."""
    result = await db.execute(
        select(Session).where(
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
    next_index = len(reponses)
    question = await _generate_next_question(exercice, reponses, next_index)

    async def event_generator():
        for token in _split_stream_tokens(question):
            payload = {"session_id": str(session.id), "text": token}
            yield f"event: token\ndata: {json.dumps(payload)}\n\n"
            await asyncio.sleep(0.02)
        yield "event: done\ndata: {}\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")


@router.post("/finish/{session_id}")
async def finish_simulation(
    session_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Terminer une simulation et generer le feedback."""
    result = await db.execute(
        select(Session).where(
            (Session.id == session_id) & (Session.utilisateur_id == current_user.id)
        )
    )
    session = result.scalars().first()

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )

    session.statut = "TERMINEE"
    session.termine_le = datetime.utcnow()

    scores = [
        r.get("score_partiel")
        for r in (session.reponses or [])
        if r.get("score_partiel") is not None
    ]
    global_score = float(sum(scores) / len(scores)) if scores else 75.0
    session.score = global_score

    ex_res = await db.execute(select(Exercice).where(Exercice.id == session.exercice_id))
    exercice = ex_res.scalars().first()
    feedback_data = await _generate_feedback(exercice, session.reponses or [], global_score)

    existing_res = await db.execute(select(Retour).where(Retour.session_id == session.id))
    feedback = existing_res.scalars().first()
    if feedback:
        feedback.score_global = feedback_data["score_global"]
        feedback.points_forts = feedback_data["points_forts"]
        feedback.ameliorations = feedback_data["ameliorations"]
        feedback.recommandations = feedback_data["recommandations"]
        feedback.genere_le = datetime.utcnow()
    else:
        feedback = Retour(
            session_id=session.id,
            score_global=feedback_data["score_global"],
            points_forts=feedback_data["points_forts"],
            ameliorations=feedback_data["ameliorations"],
            recommandations=feedback_data["recommandations"],
            genere_le=datetime.utcnow(),
        )

    db.add(session)
    db.add(feedback)
    await db.commit()
    await db.refresh(session)
    await db.refresh(feedback)

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


def _score_answer(question: dict | None, reponse: str) -> tuple[float, str, str]:
    if question and question.get("type") == "qcm":
        correct_index = question.get("reponse_correcte")
        options = question.get("options", [])
        is_correct = False
        try:
            submitted_index = int(reponse.strip())
            is_correct = submitted_index == correct_index or submitted_index - 1 == correct_index
        except ValueError:
            if isinstance(correct_index, int) and 0 <= correct_index < len(options):
                is_correct = options[correct_index].lower() == reponse.strip().lower()

        if is_correct:
            return (
                100.0,
                "Confident",
                f"Excellent, c'est la bonne reponse. {question.get('explication', '')}",
            )

        correct_text = ""
        if isinstance(correct_index, int) and 0 <= correct_index < len(options):
            correct_text = options[correct_index]
        return (
            0.0,
            "Hesitant",
            f"La bonne reponse etait: {correct_text}. {question.get('explication', '')}",
        )

    word_count = len(reponse.split())
    lowered = reponse.lower()
    if word_count < 10:
        return (
            45.0,
            "Hesitant",
            "Votre reponse est courte. Ajoutez un exemple precis et structurez avec la methode STAR.",
        )
    if not any(token in lowered for token in ("je", "mon", "ma", "mes", "nous")):
        return (
            65.0,
            "Neutral",
            "Bonne analyse. Pensez a expliciter votre role personnel et votre impact concret.",
        )
    return (
        85.0,
        "Confident",
        "Bonne structure. Pour aller plus loin, ajoutez un resultat mesurable ou un indicateur de succes.",
    )


async def _generate_next_question(exercice: Exercice, reponses: list[dict], index: int) -> str:
    questions = exercice.questions or []
    if index < len(questions):
        return questions[index].get("enonce") or _fallback_question(exercice, index, reponses)

    if len(reponses) >= max(len(questions), 3):
        return "Merci, vous avez couvert les points principaux. Cliquez sur Terminer pour obtenir votre bilan complet."

    try:
        ai_service = AIService(settings.anthropic_api_key)
        previous = [r.get("texte", "") for r in reponses if r.get("texte")]
        question = await ai_service.generate_next_question(
            previous_responses=previous,
            domaine=exercice.domaine,
            niveau=exercice.difficulte,
        )
        if question:
            return question
    except Exception:
        pass

    return _fallback_question(exercice, index, reponses)


async def _generate_feedback(exercice: Exercice | None, reponses: list[dict], score: float) -> dict:
    contexte = exercice.titre if exercice else "entretien"
    try:
        ai_service = AIService(settings.anthropic_api_key)
        feedback = await ai_service.generate_feedback(reponses, contexte)
        return _normalize_feedback(feedback, score)
    except Exception:
        return _fallback_feedback(score)


def _fallback_question(exercice: Exercice, index: int, reponses: list[dict]) -> str:
    questions = exercice.questions or []
    if index < len(questions):
        return questions[index].get("enonce") or "Pouvez-vous developper votre reponse ?"

    templates = {
        "TECHNIQUE": "Pouvez-vous expliquer le compromis technique principal de votre solution et sa complexite ?",
        "COMPORTEMENTAL": "Quel resultat mesurable avez-vous obtenu, et qu'auriez-vous fait differemment ?",
        "ETUDE_DE_CAS": "Quels risques prioritaires surveilleriez-vous pendant la mise en oeuvre ?",
        "SITUATIONNEL": "Quelle serait votre premiere action concrete dans cette situation, et pourquoi ?",
    }
    return templates.get(
        exercice.domaine,
        "Pouvez-vous donner un exemple concret pour illustrer votre raisonnement ?",
    )


def _normalize_feedback(feedback: dict, fallback_score: float) -> dict:
    normalized = _fallback_feedback(fallback_score)
    normalized["score_global"] = float(feedback.get("score_global") or fallback_score)
    for key in ("points_forts", "ameliorations"):
        items = feedback.get(key)
        if isinstance(items, list) and items:
            normalized[key] = [
                item if isinstance(item, dict) else {"domaine": "Analyse", "note": str(item), "score": 0.7}
                for item in items
            ]
    recommandations = feedback.get("recommandations")
    if isinstance(recommandations, list) and recommandations:
        normalized["recommandations"] = [str(item) for item in recommandations]
    return normalized


def _split_stream_tokens(text: str) -> list[str]:
    parts = text.split(" ")
    tokens = []
    for index, part in enumerate(parts):
        suffix = " " if index < len(parts) - 1 else ""
        tokens.append(f"{part}{suffix}")
    return tokens or [text]


def _fallback_feedback(score: float) -> dict:
    if score >= 80:
        return {
            "score_global": score,
            "points_forts": [
                {"domaine": "Communication", "note": "Expression claire et engageante.", "score": 0.9},
                {"domaine": "Structure", "note": "Reponses bien organisees et faciles a suivre.", "score": 0.85},
            ],
            "ameliorations": [
                {"domaine": "Precision", "note": "Ajouter davantage de chiffres et d'indicateurs d'impact.", "score": 0.75},
            ],
            "recommandations": [
                "Continuer avec des exercices de niveau Expert.",
                "Ajouter des KPI dans vos exemples pour renforcer votre impact.",
            ],
        }
    if score >= 60:
        return {
            "score_global": score,
            "points_forts": [
                {"domaine": "Fondamentaux", "note": "Les concepts principaux sont compris.", "score": 0.75},
            ],
            "ameliorations": [
                {"domaine": "Structure", "note": "Structurer les reponses avec la methode STAR.", "score": 0.55},
                {"domaine": "Confiance", "note": "Ralentir sur les passages complexes pour gagner en clarte.", "score": 0.6},
            ],
            "recommandations": [
                "Preparer 2 ou 3 exemples professionnels reutilisables.",
                "Reprendre les notions cles de l'exercice avant une nouvelle simulation.",
            ],
        }
    return {
        "score_global": score,
        "points_forts": [
            {"domaine": "Motivation", "note": "Bonne energie et volonte de progresser.", "score": 0.7},
        ],
        "ameliorations": [
            {"domaine": "Clarte", "note": "Developper les reponses avec plus de contexte et d'exemples.", "score": 0.4},
            {"domaine": "Technique", "note": "Revoir les notions principales abordees dans l'exercice.", "score": 0.45},
        ],
        "recommandations": [
            "Refaire l'exercice en notant les explications attendues.",
            "Utiliser la structure Situation, Tache, Action, Resultat pour chaque reponse ouverte.",
        ],
    }
