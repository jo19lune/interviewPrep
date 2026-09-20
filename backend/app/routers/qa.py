"""Routes QA autonomes et évaluations persistées."""

import logging
from datetime import datetime

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.data.database import get_db
from app.models.qa_feedback import QAFeedback
from app.models.user import User
from app.schemas.qa import (
   FeedbackRequest,
   NextQuestionRequest,
   QAReponseItem,
   QAFeedbackResponse,
   ScoreAnswerRequest,
)
from app.services.ai_service import AIService
from app.services.simulation_service import (
   normalize_feedback as _normalize_feedback,
   score_answer as _score_answer,
)

router = APIRouter(prefix="/qa", tags=["qa"])
logger = logging.getLogger(__name__)


@router.post("/next-question")
async def generate_next_question(request: NextQuestionRequest):
    """
    Génère la prochaine question d'entretien de manière autonome (sans BDD).
    """
    ai_service = AIService()
    try:
        question = await ai_service.generate_next_question(
            previous_responses=request.previous_responses,
            domaine=request.domaine,
            niveau=request.difficulte,
            sujet=request.sujet,
            question_index=request.question_index,
            total_questions=request.total_questions,
        )
        return {"question": question or "Pouvez-vous développer votre réponse ?"}
    except Exception:
        # Fallback in case of error
        return {"question": "Pouvez-vous donner un exemple concret pour illustrer votre raisonnement ?"}


@router.post("/score-answer")
async def score_answer(request: ScoreAnswerRequest):
    """
    Évalue une réponse spécifique à une question.
    """
    # Utilise la fonction interne de simulation.py pour rester cohérent
    q_dict = {"enonce": request.question, "type": "ouverte"}
    clarity_score, sentiment, coaching_tip, analysis = _score_answer(q_dict, request.answer)
    
    return {
        "score": clarity_score,
        "sentiment": sentiment,
        "coaching_tip": coaching_tip,
        "analysis": analysis,
    }


@router.post("/feedback", response_model=QAFeedbackResponse)
async def generate_feedback(
    request: FeedbackRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Génère un feedback global pour une liste de questions/réponses.
    """
    return await _create_persisted_feedback(
        request,
        current_user,
        db,
    )


async def _create_persisted_feedback(
    request: FeedbackRequest,
    current_user: User,
    db: AsyncSession,
) -> QAFeedbackResponse:
    formatted_responses, scored_responses = _prepare_responses(request.reponses)
    scores = [
        item["score_partiel"]
        for item in scored_responses
        if item.get("score_partiel") is not None
    ]
    score = round(sum(scores) / len(scores), 1) if scores else 0.0

    try:
        feedback_raw = await AIService().generate_feedback(
            formatted_responses,
            contexte=request.contexte,
            sujet=request.sujet,
        )
        normalized = _normalize_feedback(feedback_raw, score)
    except Exception:
        logger.exception("QA feedback generation failed; using local fallback")
        normalized = _normalize_feedback({}, score)

    feedback = QAFeedback(
        utilisateur_id=current_user.id,
        contexte=request.contexte,
        sujet=request.sujet,
        reponses=scored_responses,
        score_global=score,
        points_forts=normalized["points_forts"],
        ameliorations=normalized["ameliorations"],
        recommandations=normalized["recommandations"],
        genere_le=datetime.utcnow(),
    )
    db.add(feedback)
    await db.commit()
    await db.refresh(feedback)
    return QAFeedbackResponse.model_validate(feedback)


def _prepare_responses(items: list[QAReponseItem]) -> tuple[list[dict], list[dict]]:
    formatted = []
    scored = []
    current_question = None
    for item in items:
        if item.is_user:
            question = {"enonce": current_question or "", "type": "ouverte"}
            score, sentiment, tip, analysis = _score_answer(question, item.text)
            response = {
                "type": "user",
                "texte": item.text,
                "question": current_question,
                "timestamp": item.timestamp,
                "score_partiel": score,
                "sentiment": sentiment,
                "coaching_tip": tip,
                "analysis": analysis,
            }
            formatted.append(response)
            scored.append(response)
        else:
            current_question = item.text
            formatted.append({"type": "bot", "question": item.text})
    return formatted, scored
