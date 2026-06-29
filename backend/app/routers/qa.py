"""
Router pour le module QA autonome.

Fournit des points de terminaison pour générer des questions, évaluer des réponses,
et produire un feedback sans nécessiter de session en base de données (standalone).
"""

from datetime import datetime
from fastapi import APIRouter

from app.schemas.qa import NextQuestionRequest, ScoreAnswerRequest, FeedbackRequest, QAReponseItem
from app.services.ai_service import AIService
from app.services.simulation_service import score_answer as _score_answer, normalize_feedback as _normalize_feedback

router = APIRouter(prefix="/qa", tags=["qa"])


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


@router.post("/feedback")
async def generate_feedback(request: FeedbackRequest):
    """
    Génère un feedback global pour une liste de questions/réponses.
    """
    ai_service = AIService()
    
    formatted_responses = []
    for r in request.reponses:
        if r.is_user:
            formatted_responses.append({
                "texte": r.text,
                "type": "user"
            })
        else:
            formatted_responses.append({
                "question": r.text,
                "type": "bot"
            })
            
    try:
        feedback_raw = await ai_service.generate_feedback(
            formatted_responses,
            contexte=request.contexte,
            sujet=request.sujet
        )
        
        # On utilise une note moyenne par défaut car on n'a pas tout l'historique complet des scores
        score = 75.0 
        normalized = _normalize_feedback(feedback_raw, score)
        
        # S'assurer que le champ genere_le est bien renvoyé
        if "genere_le" not in normalized:
            normalized["genere_le"] = datetime.utcnow().isoformat()
            
        return normalized
        
    except Exception:
        # Fallback en cas d'erreur
        return {
            "score_global": 70.0,
            "points_forts": [],
            "ameliorations": [],
            "recommandations": ["Continuer à pratiquer"],
            "genere_le": datetime.utcnow().isoformat()
        }
