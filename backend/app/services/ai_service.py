"""Service d'integration avec modeles IA configurables (OpenAI)."""

import json
import logging
import re
import asyncio
import time
from hashlib import sha256
from typing import Any

from openai import AsyncOpenAI, APIStatusError, RateLimitError

logger = logging.getLogger(__name__)


class QuotaExceededError(Exception):
    """Levée quand le quota OpenAI est atteint (HTTP 429 / insufficient_quota)."""
    pass


class AIService:
    """Service pour interagir avec les modeles IA configures."""

    # Cache de niveau classe pour partager les requetes entre instances
    # Clé: sha256(prompt + model).hexdigest()
    # Valeur: (timestamp, response_text)
    _cache = {}
    _cache_ttl = 3600  # 1 heure de durée de vie
    
    # Tableaux de verrous pour le regroupement de requêtes concurrentes (Request Coalescing / Singleflight)
    # Clé: sha256(prompt + model).hexdigest()
    # Valeur: asyncio.Event
    _locks = {}

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
            self.client = AsyncOpenAI(api_key=api_key)

    def _clean_input(self, val: Any) -> str:
        """Nettoie et valide les chaines envoyees a l'IA (trim, suppression des caracteres de controle)."""
        if val is None:
            return ""
        text = str(val).strip()
        # Supprimer les caractères de contrôle non imprimables (ASCII 0-31 et 127)
        # pour éviter les injections de prompts complexes ou de briser la structure
        text = re.sub(r"[\x00-\x1F\x7F]", "", text)
        # S'assurer d'un encodage et decodage UTF-8 propre
        try:
            text = text.encode("utf-8", errors="ignore").decode("utf-8")
        except Exception:
            pass
        return text

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
            
        # 1. Calculer la clé unique de cache
        key_content = f"{prompt}:{model}"
        cache_key = sha256(key_content.encode("utf-8")).hexdigest()
        
        # 2. Vérifier si le résultat est déjà en cache
        now = time.time()
        if cache_key in self._cache:
            timestamp, cached_response = self._cache[cache_key]
            if now - timestamp < self._cache_ttl:
                logger.info(f"AI Cache Hit: {cache_key[:8]}")
                return cached_response
        
        # 3. Request Coalescing (Singleflight)
        # Si un appel identique est déjà en cours, on attend qu'il se termine
        wait_event = None
        is_first_request = False
        
        if cache_key in self._locks:
            wait_event = self._locks[cache_key]
        else:
            # Nous sommes la première requête, nous créons l'événement de verrouillage
            wait_event = asyncio.Event()
            self._locks[cache_key] = wait_event
            is_first_request = True
            
        if not is_first_request:
            logger.info(f"Duplicate concurrent AI request detected for {cache_key[:8]}. Waiting...")
            await wait_event.wait()
            # Une fois réveillé, le résultat doit être dans le cache
            if cache_key in self._cache:
                return self._cache[cache_key][1]
            # Si le premier appel a échoué et n'a pas pu populer le cache, on réessaie
            logger.warning(f"First AI request failed for {cache_key[:8]}. Retrying...")
            wait_event = asyncio.Event()
            self._locks[cache_key] = wait_event
            is_first_request = True
            
        # 4. Exécuter l'appel à l'API IA
        try:
            try:
                response = await self.client.chat.completions.create(
                    model=model,
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0.7,
                )
                result_text = response.choices[0].message.content or ""
                # Enregistrer dans le cache
                self._cache[cache_key] = (time.time(), result_text)
                return result_text
            except RateLimitError as e:
                logger.warning(f"Quota atteint pour le modèle {model}. Basculement nécessaire si possible.")
                raise QuotaExceededError(f"Quota exceeded for model {model}: {e}") from e
            except APIStatusError as e:
                if e.status_code == 429:
                    logger.warning(f"Quota atteint pour le modèle {model}. Basculement nécessaire si possible.")
                    raise QuotaExceededError(f"Quota exceeded for model {model}: {e}") from e
                logger.error(f"Erreur API avec le modele {model}: {e}")
                raise e
            except Exception as e:
                logger.error(f"Erreur API avec le modele {model}: {e}")
                raise e
        finally:
            # 5. Libérer le verrou pour les autres requêtes en attente
            if is_first_request:
                # Supprimer le verrou de la table
                self._locks.pop(cache_key, None)
                # Réveiller tous les waiters
                wait_event.set()

    def _build_exercise_prompt(self, domaine: str, difficulte: str, sujet: str | None, nombre_questions: int) -> str:
        domaine_clean = self._clean_input(domaine)
        difficulte_clean = self._clean_input(difficulte)
        sujet_clean = self._clean_input(sujet) if sujet else f"{domaine_clean} général"
        
        return (
            "CONTEXTE:\n"
            "Tu es dans le double rôle de recruteur exigeant et de coach professionnel bienveillant.\n"
            f"- Domaine: {domaine_clean}\n"
            f"- Sujet ciblé: {sujet_clean}\n"
            f"- Niveau de difficulté: {difficulte_clean}\n"
            f"- Nombre de questions demandées: {nombre_questions}\n\n"
            "INSTRUCTION:\n"
            "Génère un exercice d'entraînement rigoureux sous forme de questionnaire adapté à ce contexte. "
            "Les questions doivent évaluer précisément les compétences techniques ou comportementales tout en favorisant l'apprentissage. "
            "Toutes les données du questionnaire doivent être générées en français.\n\n"
            "SORTIE ATTENDUE (JSON UNIQUEMENT):\n"
            "Renvoie exclusivement un objet JSON valide sans aucune introduction ni explication. "
            "Le JSON doit correspondre exactement à cette structure :\n"
            "{\n"
            '  "titre": "Titre accrocheur de l\'exercice",\n'
            '  "description": "Une phrase résumant l\'objectif pédagogique",\n'
            f'  "domaine": "{domaine_clean}",\n'
            f'  "difficulte": "{difficulte_clean}",\n'
            '  "duree_sec": 300,\n'
            '  "etiquettes": ["tag1", "tag2", "tag3"],\n'
            '  "questions": [\n'
            '    {\n'
            '      "type": "qcm",\n'
            '      "enonce": "L\'énoncé de la question de QCM",\n'
            '      "options": ["Option A", "Option B", "Option C", "Option D"],\n'
            '      "reponse_correcte": "La réponse correcte attendue"\n'
            '    },\n'
            '    {\n'
            '      "type": "ouverte",\n'
            '      "enonce": "L\'énoncé de la question ouverte"\n'
            '    }\n'
            '  ]\n'
            "}"
        )

    def _build_feedback_prompt(self, reponses: list[dict], contexte: str, sujet: str | None) -> str:
        contexte_clean = self._clean_input(contexte)
        sujet_clean = self._clean_input(sujet) if sujet else ""
        
        reponses_formatted = []
        for r in reponses:
            if r.get("type") == "system":
                continue
            idx = int(r.get("index", 0)) + 1
            question = self._clean_input(r.get("question", ""))
            texte = self._clean_input(r.get("texte", ""))
            score = self._clean_input(r.get("score_partiel", "n/a"))
            reponses_formatted.append(
                f"Question {idx}: {question}\nRéponse du candidat: {texte}\nScore heuristique partiel: {score}/100"
            )
        
        reponses_text = "\n\n".join(reponses_formatted)
        sujet_text = f"\n- Sujet ciblé par l'utilisateur: {sujet_clean}" if sujet_clean else ""
        
        return (
            "CONTEXTE:\n"
            "Tu es un recruteur expert et un coach professionnel. Tu analyses en détail les réponses d'un candidat "
            f"fournies lors d'un entretien d'embauche dans le domaine {contexte_clean}.{sujet_text}\n\n"
            "RÉPONSES DU CANDIDAT:\n"
            f"{reponses_text}\n\n"
            "INSTRUCTION:\n"
            "Effectue une analyse approfondie des réponses du candidat. Évalue ses points forts, ses points d'amélioration "
            "et propose des recommandations personnalisées et motivantes.\n\n"
            "SORTIE ATTENDUE (JSON UNIQUEMENT):\n"
            "Renvoie exclusivement un objet JSON valide (pas d'intro ni de blabla) structuré ainsi :\n"
            "{\n"
            '  "score_global": 75.0,\n'
            '  "points_forts": [\n'
            '    {"domaine": "Nom du domaine", "note": "Description du point fort", "score": 0.8}\n'
            '  ],\n'
            '  "ameliorations": [\n'
            '    {"domaine": "Nom du domaine", "note": "Description de l\'axe d\'amélioration", "score": 0.6}\n'
            '  ],\n'
            '  "recommandations": [\n'
            '    "Conseil pratique ou méthodologique numéro 1",\n'
            '    "Conseil pratique ou méthodologique numéro 2"\n'
            '  ],\n'
            '  "synthese": "Synthèse globale constructive rédigée en français."\n'
            "}"
        )

    def _build_question_prompt(
        self,
        previous_responses: list[str],
        domaine: str,
        niveau: str,
        sujet: str | None = None,
        question_index: int = 0,
        total_questions: int = 10,
    ) -> str:
        domaine_clean = self._clean_input(domaine)
        niveau_clean = self._clean_input(niveau)
        sujet_clean = self._clean_input(sujet) if sujet else "sujet libre du domaine"
        
        responses_context = ""
        if previous_responses:
            recent_responses = []
            for r in previous_responses[-3:]:
                recent_responses.append(f"- {self._clean_input(r)[:200]}...")
            responses_context = "\n".join(recent_responses)
        else:
            responses_context = "Aucune réponse précédente (début de l'entretien)."
            
        return (
            "CONTEXTE:\n"
            "Tu agis avec un double rôle : un recruteur exigeant et un coach professionnel bienveillant.\n"
            f"- Domaine de l'entretien: {domaine_clean}\n"
            f"- Sujet ciblé: {sujet_clean}\n"
            f"- Niveau attendu du candidat: {niveau_clean}\n"
            f"- Progression: Question {question_index + 1} sur {total_questions}\n\n"
            "HISTORIQUE DU CANDIDAT (les dernières réponses pour adapter la difficulté) :\n"
            f"{responses_context}\n\n"
            "INSTRUCTION:\n"
            "Formule une seule et unique question de suivi pertinente et stimulante en français. "
            "La question doit être directe et professionnelle, visant à évaluer ses compétences (rôle recruteur) "
            "tout en l'aidant à structurer son raisonnement (rôle coach). "
            "Varie les angles de questionnement et évite de répéter une question déjà couverte.\n\n"
            "SORTIE ATTENDUE:\n"
            "Retourne uniquement l'énoncé de la question en texte brut, sans formules d'introduction ou de conclusion."
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
            "description": "Exercice genere dynamique.",
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
