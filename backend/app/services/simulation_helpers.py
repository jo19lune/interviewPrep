"""Fonctions pures partagées par le service de simulation."""

import re


def session_config(reponses):
    for item in reponses:
        if item.get("type") == "system" and isinstance(item.get("simulation_config"), dict):
            return item["simulation_config"]
    return {}


def user_responses(reponses):
    return [item for item in reponses if item.get("type") != "system"]


def score_answer(question, reponse):
    if question and question.get("type") == "qcm":
        correct = question.get("reponse_correcte")
        options = question.get("options", [])
        try:
            valid = isinstance(correct, int) and int(reponse.strip()) == correct
        except ValueError:
            valid = isinstance(correct, int) and 0 <= correct < len(options) and options[correct].lower() == reponse.lower()
        if valid:
            return 100.0, "Confident", f"Excellent, c'est la bonne reponse. {question.get('explication', '')}", {
                "pertinence": 100, "structure": 90, "precision": 100, "exemples": 80, "profondeur": 90
            }
        correct_text = options[correct] if isinstance(correct, int) and 0 <= correct < len(options) else ""
        return 0.0, "Hesitant", f"La bonne reponse etait: {correct_text}. {question.get('explication', '')}", {
            "pertinence": 0, "structure": 30, "precision": 0, "exemples": 20, "profondeur": 20
        }
    words = len(reponse.split())
    lowered = reponse.lower()
    personal = any(x in lowered for x in ("je", "mon", "ma", "mes", "nous", "j'"))
    structured = any(x in lowered for x in ("situation", "tache", "action", "resultat", "d'abord", "ensuite", "enfin"))
    metrics = bool(re.search(r"\d|%|kpi|delai|cout|temps|score|taux", lowered))
    example = any(x in lowered for x in ("exemple", "projet", "cas", "experience", "client", "equipe"))
    tradeoff = any(x in lowered for x in ("risque", "limite", "compromis", "priorite", "arbitrage", "impact"))
    analysis = {
        "pertinence": min(100, 35 + words * 2),
        "structure": 80 if structured else (60 if words >= 25 else 40),
        "precision": 85 if metrics else (65 if words >= 30 else 45),
        "exemples": 85 if example else 45,
        "profondeur": 80 if tradeoff else (65 if words >= 35 else 45),
    }
    if personal:
        analysis["pertinence"] = min(100, analysis["pertinence"] + 10)
    score = round(sum(analysis.values()) / len(analysis), 1)
    if score < 55:
        tip, sentiment = "Votre reponse est trop generale. Ajoutez votre role, un exemple concret et un resultat mesurable.", "Hesitant"
    elif score < 75:
        tip, sentiment = "Bonne base. Renforcez la structure et precisez l'impact obtenu avec un chiffre ou un resultat.", "Neutral"
    else:
        tip, sentiment = "Reponse solide. Pour viser plus haut, explicitez aussi les risques, limites ou arbitrages.", "Confident"
    return score, sentiment, tip, analysis


def normalize_feedback(feedback, fallback_score):
    normalized = fallback_feedback(fallback_score)
    normalized["score_global"] = float(feedback.get("score_global") or fallback_score)
    for key in ("points_forts", "ameliorations"):
        items = feedback.get(key)
        if isinstance(items, list) and items:
            normalized[key] = [item if isinstance(item, dict) else {"domaine": "Analyse", "note": str(item), "score": 0.7} for item in items]
    recommendations = feedback.get("recommandations")
    if isinstance(recommendations, list) and recommendations:
        normalized["recommandations"] = [str(item) for item in recommendations]
    return normalized


def fallback_feedback(score):
    if score >= 80:
        strengths = [{"domaine": "Communication", "note": "Expression claire et engageante.", "score": 0.9}]
        improvements = [{"domaine": "Precision", "note": "Ajouter davantage de chiffres et d'indicateurs d'impact.", "score": 0.75}]
    elif score >= 60:
        strengths = [{"domaine": "Fondamentaux", "note": "Les concepts principaux sont compris.", "score": 0.75}]
        improvements = [{"domaine": "Structure", "note": "Structurer les reponses avec la methode STAR.", "score": 0.55}]
    else:
        strengths = [{"domaine": "Motivation", "note": "Bonne energie et volonte de progresser.", "score": 0.7}]
        improvements = [{"domaine": "Clarte", "note": "Developper les reponses avec plus de contexte et d'exemples.", "score": 0.4}]
    return {
        "score_global": score,
        "points_forts": strengths,
        "ameliorations": improvements,
        "recommandations": ["Continuer a pratiquer et utiliser la structure STAR."],
    }


def split_stream_tokens(text):
    parts = text.split(" ")
    return [f"{part}{' ' if i < len(parts) - 1 else ''}" for i, part in enumerate(parts)] or [text]
