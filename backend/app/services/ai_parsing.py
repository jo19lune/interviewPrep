"""Parsing et valeurs de repli des réponses IA."""

import json
import re


class AIParsingMixin:
    def _parse_generate_exercise(self, content, domaine, difficulte):
        try:
            match = re.search(r"\{.*\}", content, re.DOTALL)
            parsed = json.loads(match.group()) if match else None
            if isinstance(parsed, dict):
                parsed.setdefault("domaine", domaine)
                parsed.setdefault("difficulte", difficulte)
                parsed.setdefault("duree_sec", 300)
                parsed.setdefault("difficulte_estimee", 0)
                parsed.setdefault("etiquettes", [])
                parsed.setdefault("questions", [])
                return parsed
        except (json.JSONDecodeError, AttributeError):
            pass
        return {
            "titre": f"Simulation {domaine} - {difficulte}",
            "description": "Exercice genere dynamique.",
            "domaine": domaine,
            "difficulte": difficulte,
            "duree_sec": 300,
            "etiquettes": [domaine],
            "questions": [],
        }

    def _parse_feedback_response(self, response_text):
        try:
            match = re.search(r"\{.*\}", response_text, re.DOTALL)
            parsed = json.loads(match.group()) if match else None
            if isinstance(parsed, dict):
                return parsed
        except (json.JSONDecodeError, AttributeError):
            pass
        return {
            "score_global": 75.0,
            "points_forts": [{"domaine": "Communication", "note": "Bonne clarte d'expression", "score": 0.75}],
            "ameliorations": [{"domaine": "Exemples", "note": "Approfondir les exemples", "score": 0.6}],
            "recommandations": ["Pratiquer la methode STAR"],
        }
