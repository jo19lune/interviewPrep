"""Service d'integration avec modeles IA configurables (Google GenAI)."""

import json
import logging
import re
import asyncio
from typing import Any

from google import genai

logger = logging.getLogger(__name__)


class AIService:
    """Service pour interagir avec les modeles IA configures."""

    def __init__(self, settings: Any | None = None, primary_model: str | None = None):
        from app.config.settings import settings as app_settings
        self.settings = settings or app_settings
        self.primary_model = primary_model or self.settings.ai_primary_model or self._default_model()
        self.fallback_model = self.settings.ai_fallback_model or self._fallback_model()
        self.client = None
        self._init_clients()

    def _default_model(self) -> str:
        if self.settings.ai_primary_model:
            return self.settings.ai_primary_model
        if self.openai_models:
            return self.openai_models[0]
        return ""

    def _fallback_model(self) -> str:
        if self.settings.ai_fallback_model:
            return self.settings.ai_fallback_model
        models = list(self.openai_models)
        if self.primary_model in models:
            models.remove(self.primary_model)
        return models[0] if models else ""

    @property
    def openai_models(self) -> list[str]:
        return list(self.settings.openai_models or [])

    def _init_clients(self) -> None:
        api_key = self.settings.openai_api_key
        if api_key:
            self.client = genai.Client(api_key=api_key)

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
            content = await self._complete(prompt=prompt, model=model)
            return self._parse_generate_exercise(content, domaine, difficulte)
        except Exception as exc:
            logger.error(f"Failed to generate exercise via {model}: {exc}")
            if self.fallback_model and self.fallback_model != model:
                try:
                    content = await self._complete(prompt=prompt, model=self.fallback_model)
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
            content = await self._complete(prompt=prompt, model=model)
            return self._parse_feedback_response(content)
        except Exception as exc:
            logger.error(f"Failed to generate feedback via {model}: {exc}")
            if self.fallback_model and self.fallback_model != model:
                try:
                    content = await self._complete(prompt=prompt, model=self.fallback_model)
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
            text = await self._complete(prompt=prompt, model=model)
            return text.strip()
        except Exception as exc:
            logger.error(f"Failed to generate next question via {model}: {exc}")
            if self.fallback_model and self.fallback_model != model:
                try:
                    text = await self._complete(prompt=prompt, model=self.fallback_model)
                    return text.strip()
                except Exception as fallback_exc:
                    logger.error(f"Fallback question generation failed: {fallback_exc}")
            raise

    async def _complete(self, prompt: str, model: str) -> str:
        if not self.client:
            raise RuntimeError("No AI client configured")
            
        chat = self.client.chats.create(model=model)
        
        while True:
            try:
                response = await asyncio.to_thread(
                    chat.send_message,
                    prompt
                )
                return response.text or ""
            except Exception as e:
                # Detection de limite de quota specifique a l'API
                # GenAI (429 Too Many Requests, ResourceExhausted, etc.)
                error_msg = str(e).lower()
                if "429" in error_msg or "quota" in error_msg or "resourceexhausted" in error_msg:
                    logger.warning(f"Quota atteint pour le modèle {model}. Basculement nécessaire si possible.")
                    # Lever une exception specifique pour etre attrapee dans la methode appelante
                    class QuotaExceededError(Exception):
                        pass
                    raise QuotaExceededError(f"Quota exceeded for model {model}: {e}")
                else:
                    logger.error(f"Erreur API avec le modele {model}: {e}")
                    raise e

    def _build_exercise_prompt(self, domaine: str, difficulte: str, sujet: str | None, nombre_questions: int) -> str:
        sujet_text = sujet or f"{domaine} general"
        return (
            "Tu dois adopter le double rôle de recruteur exigeant et de coach professionnel bienveillant.\n"
            f"Domaine: {domaine}\n"
            f"Sujet cible: {sujet_text}\n"
            f"Niveau: {difficulte}\n"
            f"Nombre de questions: {nombre_questions}\n\n"
            "Génère un objet JSON valide représentant un exercice avec:\n"
            "- titre: titre accrocheur\n"
            "- description: résumé pédagogique en 1 phrase expliquant l'objectif de l'exercice\n"
            "- domaine: même domaine que l'entrée\n"
            "- difficulte: même niveau que l'entrée\n"
            "- duree_sec: durée estimée en secondes\n"
            "- etiquettes: liste de 3 à 5 tags pertinents\n"
            "- questions: tableau de questions avec type (qcm|ouverte), enonce, options (pour qcm) et reponse_correcte (pour qcm)\n\n"
            "Les questions doivent tester de manière rigoureuse les compétences (rôle recruteur) tout en permettant un apprentissage (rôle coach).\n"
            "Réponds uniquement par le JSON, sans texte supplémentaire."
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
            "En tant que recruteur expert et coach professionnel, analyse en profondeur les réponses suivantes "
            f"données lors d'un entretien d'embauche dans le domaine {contexte}:{sujet_text}\n\n{reponses_text}\n\n"
            "Fournis une analyse structurée JSON avec:\n"
            "- score_global: évaluation précise sous forme de score de 0 à 100 reflétant le niveau du candidat\n"
            "- points_forts: liste d'objets avec domaine, note (description), score (évaluation du point fort)\n"
            "- ameliorations: liste d'objets avec domaine, note (description), score (évaluation du point à améliorer)\n"
            "- recommandations: liste de conseils pratiques et constructifs personnalisés pour aider le candidat à progresser\n"
            "- synthese: court bilan global combinant l'évaluation du recruteur et les encouragements du coach\n\n"
            "Réponds en JSON valide uniquement, sans aucun texte introductif."
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
            "Tu agis avec un double rôle : un recruteur exigeant et un coach professionnel bienveillant.\n\n"
            f"Domaine: {domaine}\nSujet cible: {sujet_text}\nNiveau candidat: {niveau}\n"
            f"Question: {question_index + 1}/{total_questions}\n{responses_context}\n"
            "Pose une seule question de suivi pertinente et adaptée au niveau du candidat. "
            "La question doit permettre d'évaluer rigoureusement ses compétences (rôle recruteur) "
            "tout en l'aidant à structurer sa pensée (rôle coach). "
            "Varie les angles: bases, mise en pratique, résolution de problème, communication, limites, impact, risques et arbitrages. "
            "Ne répète pas une question déjà couverte. Question claire, professionnelle, stimulante et liée au sujet."
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
