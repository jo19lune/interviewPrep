"""Logique metier des simulations d'entretien."""

import re

from app.models.exercice import Exercice
from app.services.ai_service import AIService


def score_answer(question: dict | None, reponse: str) -> tuple[float, str, str, dict]:
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
                {
                    "pertinence": 100,
                    "structure": 90,
                    "precision": 100,
                    "exemples": 80,
                    "profondeur": 90,
                },
            )

        correct_text = ""
        if isinstance(correct_index, int) and 0 <= correct_index < len(options):
            correct_text = options[correct_index]
        return (
            0.0,
            "Hesitant",
            f"La bonne reponse etait: {correct_text}. {question.get('explication', '')}",
            {
                "pertinence": 0,
                "structure": 30,
                "precision": 0,
                "exemples": 20,
                "profondeur": 20,
            },
        )

    word_count = len(reponse.split())
    lowered = reponse.lower()
    has_personal_role = any(token in lowered for token in ("je", "mon", "ma", "mes", "nous", "j'"))
    has_structure = any(token in lowered for token in ("situation", "tache", "action", "resultat", "d'abord", "ensuite", "enfin"))
    has_metrics = bool(re.search(r"\d|%|kpi|delai|cout|temps|score|taux", lowered))
    has_example = any(token in lowered for token in ("exemple", "projet", "cas", "experience", "client", "equipe"))
    has_tradeoff = any(token in lowered for token in ("risque", "limite", "compromis", "priorite", "arbitrage", "impact"))

    analysis = {
        "pertinence": min(100, 35 + word_count * 2),
        "structure": 80 if has_structure else (60 if word_count >= 25 else 40),
        "precision": 85 if has_metrics else (65 if word_count >= 30 else 45),
        "exemples": 85 if has_example else 45,
        "profondeur": 80 if has_tradeoff else (65 if word_count >= 35 else 45),
    }
    if has_personal_role:
        analysis["pertinence"] = min(100, analysis["pertinence"] + 10)

    score = round(sum(analysis.values()) / len(analysis), 1)
    if score < 55:
        return (
            score,
            "Hesitant",
            "Votre reponse est trop generale. Ajoutez votre role, un exemple concret et un resultat mesurable.",
            analysis,
        )
    if score < 75:
        return (
            score,
            "Neutral",
            "Bonne base. Renforcez la structure et precisez l'impact obtenu avec un chiffre ou un resultat.",
            analysis,
        )
    return (
        score,
        "Confident",
        "Reponse solide. Pour viser plus haut, explicitez aussi les risques, limites ou arbitrages.",
        analysis,
    )


async def generate_next_question(exercice: Exercice, reponses: list[dict], index: int) -> str:
    config = session_config(reponses)
    target_count = int(config.get("nombre_questions") or 10)
    sujet = config.get("sujet")
    user_reponses = user_responses(reponses)
    if len(user_reponses) >= target_count:
        return "Merci, vous avez termine toutes les questions. Cliquez sur Terminer pour obtenir votre bilan complet."

    questions = exercice.questions or []
    if index < len(questions):
        return questions[index].get("enonce") or fallback_question(exercice, index, reponses)

    try:
        ai_service = AIService()
        previous = [r.get("texte", "") for r in user_reponses if r.get("texte")]
        question = await ai_service.generate_next_question(
            previous_responses=previous,
            domaine=exercice.domaine,
            niveau=exercice.difficulte,
            sujet=sujet,
            question_index=index,
            total_questions=target_count,
        )
        if question:
            return question
    except Exception:
        pass

    return fallback_question(exercice, index, reponses)


async def generate_feedback(exercice: Exercice | None, reponses: list[dict], score: float) -> dict:
    contexte = exercice.titre if exercice else "entretien"
    config = session_config(reponses)
    try:
        ai_service = AIService()
        feedback = await ai_service.generate_feedback(
            user_responses(reponses),
            contexte,
            sujet=config.get("sujet"),
        )
        return normalize_feedback(feedback, score)
    except Exception:
        return fallback_feedback(score)


def fallback_question(exercice: Exercice, index: int, reponses: list[dict]) -> str:
    config = session_config(reponses)
    sujet = config.get("sujet")
    sujet_suffix = f" sur {sujet}" if sujet else ""
    questions = exercice.questions or []
    if index < len(questions):
        return questions[index].get("enonce") or "Pouvez-vous developper votre reponse ?"

    templates = {
        "TECHNIQUE": f"Pouvez-vous expliquer un compromis technique important{sujet_suffix} et sa complexite ?",
        "COMPORTEMENTAL": f"Quel resultat mesurable avez-vous obtenu{sujet_suffix}, et qu'auriez-vous fait differemment ?",
        "ETUDE_DE_CAS": f"Quels risques prioritaires surveilleriez-vous{sujet_suffix} pendant la mise en oeuvre ?",
        "SITUATIONNEL": f"Quelle serait votre premiere action concrete{sujet_suffix}, et pourquoi ?",
    }
    return templates.get(
        exercice.domaine,
        "Pouvez-vous donner un exemple concret pour illustrer votre raisonnement ?",
    )


def session_config(reponses: list[dict]) -> dict:
    for item in reponses:
        if item.get("type") == "system" and isinstance(item.get("simulation_config"), dict):
            return item["simulation_config"]
    return {}


def user_responses(reponses: list[dict]) -> list[dict]:
    return [item for item in reponses if item.get("type") != "system"]


def normalize_feedback(feedback: dict, fallback_score: float) -> dict:
    normalized = fallback_feedback(fallback_score)
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


def split_stream_tokens(text: str) -> list[str]:
    parts = text.split(" ")
    tokens = []
    for index, part in enumerate(parts):
        suffix = " " if index < len(parts) - 1 else ""
        tokens.append(f"{part}{suffix}")
    return tokens or [text]


def fallback_feedback(score: float) -> dict:
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
