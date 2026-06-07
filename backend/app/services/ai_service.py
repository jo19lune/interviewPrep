"""Service d'integration avec modeles IA configurables (OpenAI, Anthropic)."""

import asyncio
import json
import logging
import os
import re
from typing import Any

import anthropic
import openai

logger = logging.getLogger(__name__)


class AIService:
    """Service pour interagir avec les modeles IA configures."""

    def __init__(self, settings: Any | None = None):
        from app.config.settings import settings as app_settings
        self.settings = settings or app_settings
        self.provider = self._resolve_provider()
        self.primary_model = self.settings.ai_primary_model or self._default_model()
        self.fallback_model = self.settings.ai_fallback_model or self._fallback_model()
        self.openai_client = None
        self.anthropic_client = None
        self._init_clients()

    def _resolve_provider(self) -> str:
        explicit = (self.settings.ai_provider or "auto").lower()
        if explicit in {"openai", "anthropic"}:
            return explicit
        if self.settings.openai_api_key:
            return "openai"
        if self.settings.anthropic_api_key:
            return "anthropic"
        return "openai"

    def _default_model(self) -> str:
        if self.openai_models:
            return self.openai_models[0]
        if self.settings.anthropic_api_key:
            return "claude-3-5-sonnet-20241022"
        return "gpt-4o-mini"

    def _fallback_model(self) -> str:
        if self.provider == "openai":
            models = list(self.openai_models)
            if self.primary_model in models:
                models.remove(self.primary_model)
            return models[0] if models else ""
        if self.provider == "anthropic":
            return "claude-3-haiku-20240307"
        return ""

    @property
    def openai_models(self) -> list[str]:
        return list(self.settings.openai_models or [])

    def _init_clients(self) -> None:
        if self.provider == "openai" and self.settings.openai_api_key:
            self.openai_client = openai.AsyncOpenAI(api_key=self.settings.openai_api_key)
        elif self.provider == "anthropic" and self.settings.anthropic_api_key:
            self.anthropic_client = anthropic.AsyncAnthropic(api_key=self.settings.anthropic_api_key)
        else:
            if self.settings.openai_api_key:
                self.openai_client = openai.AsyncOpenAI(api_key=self.settings.openai_api_key)
            elif self.settings.anthropic_api_key:
                self.anthropic_client = anthropic.AsyncAnthropic(api_key=self.settings.anthropic_api_key)

    async def generate_exercise(
        self,
        domaine: str,
        difficulte: str,
        sujet: str | None = None,
        nombre_questions: int = 10,
        temperature: float = 0.7,
    ) -> dict:
        """Generer un exercice complet adapte au domaine/niveau."""
        prompt = self._build_exercise_prompt(domaine, difficulte, sujet, nombre_questions)
        model = self.primary_model or self._default_model()
        try:
            content = await self._complete(prompt=prompt, model=model, temperature=temperature, max_tokens=2000)
            return self._parse_generate_exercise(content, domaine, difficulte)
        except Exception as exc:
            logger.error(f"Failed to generate exercise via {model}: {exc}")
            if self.fallback_model and self.fallback_model != model:
                try:
                    content = await self._complete(prompt=prompt, model=self.fallback_model, temperature=temperature, max_tokens=2000)
                    return self._parse_generate_exercise(content, domaine, difficulte)
                except Exception as fallback_exc:
                    logger.error(f"Fallback exercise generation failed: {fallback_exc}")
            raise

    async def generate_feedback(
        self,
        reponses: list[dict],
        contexte: str,
        sujet: str | None = None,
        temperature: float = 0.7,
    ) -> dict:
        """Generer un feedback structure base sur les reponses."""
        prompt = self._build_feedback_prompt(reponses, contexte, sujet)
        model = self.primary_model or self._default_model()
        try:
            content = await self._complete(prompt=prompt, model=model, temperature=temperature, max_tokens=1200)
            return self._parse_feedback_response(content)
        except Exception as exc:
            logger.error(f"Failed to generate feedback via {model}: {exc}")
            if self.fallback_model and self.fallback_model != model:
                try:
                    content = await self._complete(prompt=prompt, model=self.fallback_model, temperature=temperature, max_tokens=1200)
                    return self._parse_feedback_response(content)
                except Exception as fallback_exc:
                    logger.error(f"Fallback feedback generation failed: {fallback_exc}")
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
        model = self.primary_model or self._default_model()
        try:
            text = await self._complete(prompt=prompt, model=model, temperature=temperature, max_tokens=600)
            return text.strip()
        except Exception as exc:
            logger.error(f"Failed to generate next question via {model}: {exc}")
            if self.fallback_model and self.fallback_model != model:
                try:
                    text = await self._complete(prompt=prompt, model=self.fallback_model, temperature=temperature, max_tokens=600)
                    return text.strip()
                except Exception as fallback_exc:
                    logger.error(f"Fallback question generation failed: {fallback_exc}")
            raise

    async def _complete(self, prompt: str, model: str, temperature: float, max_tokens: int) -> str:
        if self.openai_client:
            completion = await self.openai_client.chat.completions.create(
                model=model,
                messages=[{"role": "user", "content": prompt}],
                temperature=temperature,
                max_tokens=max_tokens,
            )
            return completion.choices[0].message.content or ""
        if self.anthropic_client:
            message = await self.anthropic_client.messages.create(
                model=model,
                max_tokens=max_tokens,
                temperature=temperature,
                messages=[{"role": "user", "content": prompt}],
            )
            parts = message.content or []
            text = "".join(part.text for part in parts if getattr(part, "text", None))
            return text
        raise RuntimeError("No AI client configured")

    def _build_exercise_prompt(self, domaine: str, difficulte: str, sujet: str | None, nombre_questions: int) -> str:
        sujet_text = sujet or f"{domaine} general"
        return (
            "Tu es un expert en preparation d'entretiens professionnels.\n"
            f"Domaine: {domaine}\n"
            f"Sujet cible: {sujet_text}\n"
            f"Niveau: {difficulte}\n"
            f"Nombre de questions: {nombre_questions}\n\n"
            "Genere un objet JSON valide representant un exercice avec:\n"
            "- titre: titre accrocheur\n"
            "- description: resume pedagogique en 1 phrase\n"
            "- domaine: meme domaine que l'entree\n"
            "- difficulte: meme niveau que l'entree\n"
            "- duree_sec: duree estimee en secondes\n"
            "- etiquettes: liste de 3 a 5 tags\n"
            "- questions: tableau de questions avec type (qcm|ouverte), enonce, options et reponse_correcte pour qcm\n\n"
            "Reponds uniquement par le JSON, sans texte supplementaire."
        )

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
        return (
            "Analyse les reponses suivantes donnees lors d'un entretien d'embauche dans le domaine "
            f"{contexte}:{sujet_text}\n\n{reponses_text}\n\n"
            "Fournis une analyse structuree JSON avec:\n"
            "- score_global: note de 0 a 100\n"
            "- points_forts: liste d'objets avec domaine, note, score\n"
            "- ameliorations: liste d'objets avec domaine, note, score\n"
            "- recommandations: liste des conseils pratiques\n"
            "- synthese: court bilan global\n\n"
            "Reponds en JSON valide uniquement."
        )

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
        return (
            "Tu es un recruteur experimente en entretiens d'embauche.\n\n"
            f"Domaine: {domaine}\nSujet cible: {sujet_text}\nNiveau candidat: {niveau}\n"
            f"Question: {question_index + 1}/{total_questions}\n{responses_context}\n"
            "Pose une seule question de suivi pertinente et adaptee au niveau du candidat. "
            "Varie les angles: bases, mise en pratique, resolution de probleme, communication, limites, impact, risques et arbitrages. "
            "Ne repete pas une question deja couverte. Question professionnelle, claire, courte et liee au sujet."
        )

    def _parse_generate_exercise(self, content: str, domaine: str, difficulte: str) -> dict:
        try:
            match = re.search(r"\{.*\}", content, re.DOTALL)
            if match:
                parsed = json.loads(match.group())
                if isinstance(parsed, dict):
                    parsed.setdefault("domaine", domaine)
                    parsed.setdefault("difficulte", difficulte)
                    parsed.setdefault("duree_sec", 300)
                    parsed.setdefault("etiquettes", [])
                    parsed.setdefault("questions", [])
                    return parsed
        except (json.JSONDecodeError, AttributeError):
            pass
        return {
            "titre": f"Simulation {domaine} - {difficulte}",
            "description": "Exercice genere dynamiquement.",
            "domaine": domaine,
            "difficulte": difficulte,
            "duree_sec": 300,
            "etiquettes": [domaine],
            "questions": [],
        }

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
