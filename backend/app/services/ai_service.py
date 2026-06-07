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
        temperature: float = 0.7,
    ) -> dict:
        """Generer un feedback base sur les reponses."""
        prompt = self._build_feedback_prompt(reponses, contexte)

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
        temperature: float = 0.7,
    ) -> str:
        """Generer la prochaine question adaptee."""
        prompt = self._build_question_prompt(previous_responses, domaine, niveau)

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

    def _build_feedback_prompt(self, reponses: list[dict], contexte: str) -> str:
        reponses_text = "\n".join([f"- {r.get('texte', '')}" for r in reponses])

        return f"""Analyse les reponses suivantes donnees lors d'un entretien d'embauche dans le domaine {contexte}:

{reponses_text}

Fournis une analyse structuree JSON avec:
- score_global: note de 0 a 100
- points_forts: liste des points forts observes
- ameliorations: liste des axes d'amelioration
- recommandations: liste des conseils pratiques

Reponds en JSON valide uniquement."""

    def _build_question_prompt(self, previous_responses: list[str], domaine: str, niveau: str) -> str:
        responses_context = ""
        if previous_responses:
            recent_responses = "\n".join([f"- {response[:200]}..." for response in previous_responses[-3:]])
            responses_context = f"\n\nReponses precedentes pour adaptation:\n{recent_responses}"

        return f"""Tu es un recruteur experimente en entretiens d'embauche.

Domaine: {domaine}
Niveau candidat: {niveau}
{responses_context}

Pose une question de suivi pertinente et adaptee au niveau du candidat.
La question doit etre professionnelle, claire et pertinente pour le domaine."""

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
