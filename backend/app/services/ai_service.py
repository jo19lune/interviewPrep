"""Façade publique du service IA."""

import logging
from typing import Any

from .ai_client import AIClientMixin
from .ai_client import QuotaExceededError
from .ai_parsing import AIParsingMixin
from .ai_prompts import AIPromptMixin

logger = logging.getLogger(__name__)


class AIService(AIClientMixin, AIPromptMixin, AIParsingMixin):
    def __init__(self, settings: Any | None = None, primary_model: str | None = None):
        from app.config.settings import settings as app_settings
        self.settings = settings or app_settings
        self.primary_model = primary_model or self.settings.ai_primary_model or self._default_model()
        self.fallback_model = self.settings.ai_fallback_model or self._fallback_model()
        self.client = None
        self._init_clients()

    def _default_model(self):
        return self.settings.ai_primary_model or (self.openai_models[0] if self.openai_models else "")

    def _fallback_model(self):
        models = list(self.openai_models)
        if self.primary_model in models:
            models.remove(self.primary_model)
        return self.settings.ai_fallback_model or (models[0] if models else "")

    @property
    def openai_models(self):
        return list(self.settings.openai_models or [])

    async def _with_fallback(self, prompt, parser, model):
        try:
            return parser(await self._complete(prompt, model))
        except Exception as exc:
            logger.error("AI request failed via %s: %s", model, exc)
            if self.fallback_model and self.fallback_model != model:
                return parser(await self._complete(prompt, self.fallback_model))
            raise

    async def generate_exercise(self, domaine, difficulte, sujet=None, nombre_questions=10, temperature=0.7):
        prompt = self._build_exercise_prompt(domaine, difficulte, sujet, nombre_questions)
        return await self._with_fallback(
            prompt, lambda text: self._parse_generate_exercise(text, domaine, difficulte),
            self.primary_model or self._default_model(),
        )

    async def generate_feedback(self, reponses, contexte, sujet=None, temperature=0.7):
        prompt = self._build_feedback_prompt(reponses, contexte, sujet)
        return await self._with_fallback(
            prompt,
            self._parse_feedback_response,
            self.primary_model or self._default_model(),
        )

    async def generate_next_question(self, previous_responses, domaine, niveau, sujet=None,
                                     question_index=0, total_questions=10, temperature=0.7):
        prompt = self._build_question_prompt(
            previous_responses, domaine, niveau, sujet, question_index, total_questions
        )
        return await self._with_fallback(
            prompt, lambda text: text.strip(), self.primary_model or self._default_model()
        )

    async def transcribe_audio(self, audio_file_path):
        if not self.client:
            raise RuntimeError("No AI client configured")
        try:
            with open(audio_file_path, "rb") as audio_file:
                transcript = await self.client.audio.transcriptions.create(
                    model="whisper-1", file=audio_file
                )
            return transcript.text.strip()
        except Exception:
            logger.exception("Audio transcription failed")
            raise
