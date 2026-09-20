"""Construction des prompts envoyés au fournisseur IA."""

import re
from typing import Any


class AIPromptMixin:
    def _clean_input(self, val: Any) -> str:
        if val is None:
            return ""
        text = re.sub(r"[\x00-\x1F\x7F]", "", str(val).strip())
        return text.encode("utf-8", errors="ignore").decode("utf-8")

    def _build_exercise_prompt(self, domaine, difficulte, sujet, nombre_questions):
        d, n = self._clean_input(domaine), self._clean_input(difficulte)
        s = self._clean_input(sujet) if sujet else f"{d} général"
        return (
            "CONTEXTE:\nTu es recruteur et coach professionnel.\n"
            f"- Domaine: {d}\n- Sujet ciblé: {s}\n- Niveau: {n}\n"
            f"- Nombre de questions: {nombre_questions}\n\n"
            "Génère un exercice en français. Retourne exclusivement ce JSON valide:\n"
            '{"titre":"Titre","description":"Objectif","domaine":"%s",'
            '"difficulte":"%s","duree_sec":300,"difficulte_estimee":7,'
            '"etiquettes":[],"questions":[]}' % (d, n)
        )

    def _build_feedback_prompt(self, reponses, contexte, sujet):
        c = self._clean_input(contexte)
        s = self._clean_input(sujet) if sujet else ""
        rows = []
        for response in reponses:
            if response.get("type") == "system":
                continue
            idx = int(response.get("index", 0)) + 1
            rows.append(
                f"Question {idx}: {self._clean_input(response.get('question', ''))}\n"
                f"Réponse: {self._clean_input(response.get('texte', ''))}\n"
                f"Score: {self._clean_input(response.get('score_partiel', 'n/a'))}/100"
            )
        subject = f"\nSujet: {s}" if s else ""
        responses_text = "\n\n".join(rows)
        return (
            f"Tu es recruteur expert. Analyse l'entretien dans {c}.{subject}\n"
            f"RÉPONSES:\n{responses_text}\n"
            'Retourne uniquement un JSON avec "score_global", "points_forts", '
            '"ameliorations", "recommandations" et "synthese".'
        )

    def _build_question_prompt(
        self, previous_responses, domaine, niveau, sujet=None,
        question_index=0, total_questions=10
    ):
        d, n = self._clean_input(domaine), self._clean_input(niveau)
        s = self._clean_input(sujet) if sujet else "sujet libre du domaine"
        history = "\n".join(
            f"- {self._clean_input(item)[:200]}..." for item in previous_responses[-3:]
        ) or "Aucune réponse précédente (début de l'entretien)."
        return (
            "Tu es recruteur et coach. Formule une seule question de suivi en français.\n"
            f"Domaine: {d}\nSujet: {s}\nNiveau: {n}\n"
            f"Progression: question {question_index + 1}/{total_questions}\n"
            f"Historique:\n{history}\nRetourne uniquement la question."
        )
