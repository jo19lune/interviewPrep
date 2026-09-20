"""Génération des questions et feedback avec repli local."""

import logging

from app.services.ai_service import AIService
from .simulation_helpers import fallback_feedback, normalize_feedback, session_config, user_responses

logger = logging.getLogger(__name__)


def fallback_question(exercice, index, reponses):
    config = session_config(reponses)
    suffix = f" sur {config.get('sujet')}" if config.get("sujet") else ""
    questions = exercice.questions or []
    if index < len(questions):
        return questions[index].get("enonce") or "Pouvez-vous developper votre reponse ?"
    templates = {
        "TECHNIQUE": f"Pouvez-vous expliquer un compromis technique important{suffix} et sa complexite ?",
        "COMPORTEMENTAL": f"Quel resultat mesurable avez-vous obtenu{suffix}, et qu'auriez-vous fait differemment ?",
        "ETUDE_DE_CAS": f"Quels risques prioritaires surveilleriez-vous{suffix} pendant la mise en oeuvre ?",
        "SITUATIONNEL": f"Quelle serait votre premiere action concrete{suffix}, et pourquoi ?",
    }
    return templates.get(exercice.domaine, "Pouvez-vous donner un exemple concret pour illustrer votre raisonnement ?")


async def generate_next_question(exercice, reponses, index, model=None):
    config = session_config(reponses)
    target = int(config.get("nombre_questions") or 10)
    if len(user_responses(reponses)) >= target:
        return "Merci, vous avez termine toutes les questions. Cliquez sur Terminer pour obtenir votre bilan complet."
    questions = exercice.questions or []
    if index < len(questions):
        return questions[index].get("enonce") or fallback_question(exercice, index, reponses)
    try:
        service = AIService(primary_model=model)
        return (await service.generate_next_question(
            [r.get("texte", "") for r in user_responses(reponses) if r.get("texte")],
            exercice.domaine, exercice.difficulte, config.get("sujet"), index, target
        )).strip()
    except Exception:
        logger.exception("AI question generation failed; using local fallback")
        return fallback_question(exercice, index, reponses)


async def generate_feedback(exercice, reponses, score, model=None):
    config = session_config(reponses)
    try:
        feedback = await AIService(primary_model=model).generate_feedback(
            user_responses(reponses), exercice.titre if exercice else "entretien", config.get("sujet")
        )
        return normalize_feedback(feedback, score)
    except Exception:
        logger.exception("AI feedback generation failed; using local fallback")
        return fallback_feedback(score)
