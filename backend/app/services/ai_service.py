"""Service d'integration avec Claude AI."""

import asyncio
import json
import logging
import re

import anthropic

logger = logging.getLogger(__name__)


class AIService:
    """Service pour interagir avec Claude AI."""

    def __init__(self, api_key: str):
        if not api_key:
            raise ValueError("Anthropic API key is missing")
        self.client = anthropic.Anthropic(api_key=api_key)

    async def generate_feedback(
        self,
        reponses: list[dict],
        contexte: str,
        sujet: str | None = None,
        temperature: float = 0.7,
    ) -> dict:
        """Generer un feedback base sur les reponses."""
        prompt = self._build_feedback_prompt(reponses, contexte, sujet)

        try:
            message = await asyncio.to_thread(
                self.client.messages.create,
                model="claude-3-5-sonnet-20241022",
                max_tokens=1024,
                temperature=temperature,
                messages=[{"role": "user", "content": prompt}],
            )
            return self._parse_feedback_response(message.content[0].text)
        except Exception as e:
            logger.error(f"Error generating feedback: {e}")
            raise

    async def generate_next_question(
        self,
        previous_responses: list[str],
        domaine: str,
        niveau: str,
        sujet: str | None = None,
        question_index: int = 0,
        total_questions: int = 10,
        temperature: float = 0.7,
    ) -> str:
        """Generer la prochaine question adaptee."""
        prompt = self._build_question_prompt(
            previous_responses,
            domaine,
            niveau,
            sujet,
            question_index,
            total_questions,
        )

        try:
            message = await asyncio.to_thread(
                self.client.messages.create,
                model="claude-3-5-sonnet-20241022",
                max_tokens=500,
                temperature=temperature,
                messages=[{"role": "user", "content": prompt}],
            )
            return message.content[0].text.strip()
        except Exception as e:
            logger.error(f"Error generating question: {e}")
            raise

    def _build_feedback_prompt(self, reponses: list[dict], contexte: str, sujet: str | None) -> str:
        reponses_text = "\n".join(
            [
                (
                    f"Q{r.get('index', 0) + 1}: {r.get('question', 'Question non fournie')}\n"
                    f"Reponse: {r.get('texte', '')}\n"
                    f"Score heuristique: {r.get('score_partiel', 'n/a')}/100"
                )
                for r in reponses
                if r.get("type") != "system"
            ]
        )
        sujet_text = f"\nSujet cible choisi par l'utilisateur: {sujet}" if sujet else ""

        return f"""Analyse les reponses suivantes donnees lors d'un entretien d'embauche dans le domaine {contexte}:
{sujet_text}

{reponses_text}

Fournis une analyse structuree JSON avec:
- score_global: note de 0 a 100
- points_forts: liste d'objets avec domaine, note, score
- ameliorations: liste d'objets avec domaine, note, score
- recommandations: liste des conseils pratiques
- synthese: court bilan global

Evalue la pertinence par rapport au sujet, la structure, la precision, les exemples, la profondeur technique/metier et la clarte.

Reponds en JSON valide uniquement."""

    def _build_question_prompt(
        self,
        previous_responses: list[str],
        domaine: str,
        niveau: str,
        sujet: str | None,
        question_index: int,
        total_questions: int,
    ) -> str:
        responses_context = ""
        if previous_responses:
            recent_responses = "\n".join([f"- {response[:200]}..." for response in previous_responses[-3:]])
            responses_context = f"\n\nReponses precedentes pour adaptation:\n{recent_responses}"
        sujet_text = sujet or "sujet libre du domaine"

        return f"""Tu es un recruteur experimente en entretiens d'embauche.

Domaine: {domaine}
Sujet cible: {sujet_text}
Niveau candidat: {niveau}
Question: {question_index + 1}/{total_questions}
{responses_context}

Pose une seule question de suivi pertinente et adaptee au niveau du candidat.
Varie les angles: bases, mise en pratique, resolution de probleme, communication, limites, impact, risques et arbitrages.
Ne repete pas une question deja couverte. La question doit etre professionnelle, claire, courte et directement liee au sujet cible."""

    def _parse_feedback_response(self, response_text: str) -> dict:
        try:
            json_match = re.search(r"\{.*\}", response_text, re.DOTALL)
            if json_match:
                feedback = json.loads(json_match.group())
                if isinstance(feedback, dict):
                    return feedback
        except (json.JSONDecodeError, AttributeError):
            pass

        return {
            "score_global": 75.0,
            "points_forts": [
                {"domaine": "Communication", "note": "Bonne clarte d'expression", "score": 0.75}
            ],
            "ameliorations": [
                {"domaine": "Exemples", "note": "Approfondir les exemples", "score": 0.6}
            ],
            "recommandations": ["Pratiquer la methode STAR"],
        }
