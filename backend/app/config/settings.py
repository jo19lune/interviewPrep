"""
Module de configuration de l'application.

Ce module gère le chargement et la validation de toutes les variables
d'environnement nécessaires à l'exécution de l'application via Pydantic.
Il définit également la classe Settings principale accessible globalement.
"""

import json
import os
from typing import List

from pydantic import AnyHttpUrl, Field, field_validator, AliasChoices
from pydantic_settings import BaseSettings, SettingsConfigDict


def parse_frontend_urls(raw_value: str | None) -> list[str]:
    """
    Parse les URLs du frontend autorisées pour le CORS depuis la configuration.

    Peut parser à partir d'une chaîne de type JSON array (ex: `["http://a.com"]`)
    ou d'une liste séparée par des virgules (ex: `http://a.com,http://b.com`).

    Args:
        raw_value (str | None): La valeur brute contenant les URLs.

    Returns:
        list[str]: Une liste propre d'URLs valides.
    """
    if not raw_value:
        return ["http://localhost:3000"]

    raw_value = raw_value.strip()
    if raw_value.startswith("[") and raw_value.endswith("]"):
        try:
            parsed = json.loads(raw_value)
            return [str(url).strip() for url in parsed if str(url).strip()]
        except json.JSONDecodeError:
            raw_value = raw_value[1:-1]

    return [url.strip().strip('"').strip("'") for url in raw_value.split(",") if url.strip()]


class Settings(BaseSettings):
    """
    Classe définissant les paramètres globaux de configuration.

    Hérite de `BaseSettings` (pydantic_settings) pour lire automatiquement
    les valeurs depuis un fichier `.env` ou depuis les variables système.
    """

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Base de donnees
    database_url: str = Field(
        default="sqlite+aiosqlite:///./interviewprep_dev.db",
        validation_alias="DATABASE_URL",
        description="L'URL de connexion à la base de données principale."
    )
    redis_url: str = Field(
        default="redis://localhost:6379/0",
        validation_alias="REDIS_URL",
        description="L'URL de connexion à l'instance Redis."
    )

    # Securite JWT
    secret_key: str = Field(
        default="dev-only-change-me",
        validation_alias="SECRET_KEY",
        description="Clé secrète utilisée pour signer les tokens JWT."
    )
    access_token_expire_minutes: int = Field(
        default=15,
        validation_alias="ACCESS_TOKEN_EXPIRE_MINUTES",
        description="Durée de validité d'un Access Token en minutes."
    )
    refresh_token_expire_minutes: int = Field(
        default=1440,
        validation_alias="REFRESH_TOKEN_EXPIRE_MINUTES",
        description="Durée de validité d'un Refresh Token en minutes."
    )
    algorithm: str = Field(
        default="HS256",
        validation_alias="ALGORITHM",
        description="Algorithme cryptographique pour la signature JWT."
    )

    # Rate Limiting
    max_attempts: int = Field(
        default=5,
        validation_alias="MAX_ATTEMPTS",
        description="Nombre maximum de tentatives de connexion échouées."
    )
    lockout_time: int = Field(
        default=300,
        validation_alias="LOCKOUT_TIME",
        description="Temps de verrouillage en secondes après dépassement des tentatives."
    )

    # AI providers
    anthropic_api_key: str = Field(
        default="",
        validation_alias="ANTHROPIC_API_KEY",
        description="Clé API pour Anthropic Claude."
    )
    openai_api_key: str = Field(
        default="",
        validation_alias="OPENAI_API_KEY",
        description="Clé API pour OpenAI."
    )
    openai_models: List[str] = Field(
        default=[],
        description="Liste dynamiquement chargée des modèles OpenAI disponibles."
    )
    ai_provider: str = Field(
        default="auto",
        validation_alias="AI_PROVIDER",
        description="Fournisseur d'IA par défaut à utiliser."
    )
    ai_primary_model: str = Field(
        default="",
        validation_alias="AI_PRIMARY_MODEL",
        description="Nom du modèle principal à utiliser."
    )
    ai_fallback_model: str = Field(
        default="",
        validation_alias="AI_FALLBACK_MODEL",
        description="Modèle de secours en cas d'échec du modèle principal."
    )
    ai_feature_generate_exercises: bool = Field(
        default=True,
        validation_alias="AI_FEATURE_GENERATE_EXERCISES",
        description="Activation de la fonctionnalité IA de génération d'exercices."
    )
    ai_feature_generate_questions: bool = Field(
        default=True,
        validation_alias="AI_FEATURE_GENERATE_QUESTIONS",
        description="Activation de la fonctionnalité IA de génération de questions."
    )
    ai_feature_generate_feedback: bool = Field(
        default=True,
        validation_alias="AI_FEATURE_GENERATE_FEEDBACK",
        description="Activation de la fonctionnalité IA de génération de retours."
    )

    # Email
    email_host: str = Field(
        default="smtp.gmail.com",
        validation_alias="SMTP_HOST",
        description="Hôte du serveur SMTP."
    )
    email_port: int = Field(
        default=587,
        validation_alias="SMTP_PORT",
        description="Port du serveur SMTP."
    )
    email_username: str = Field(
        default="",
        validation_alias=AliasChoices("SMTP_USER"),
        description="Nom d'utilisateur pour l'authentification SMTP."
    )
    email_password: str = Field(
        default="",
        validation_alias=AliasChoices("SMTP_PASSWORD"),
        description="Mot de passe ou App Password pour SMTP."
    )
    email_use_tls: bool = Field(
        default=True,
        validation_alias="EMAIL_USE_TLS",
        description="Spécifie si TLS doit être utilisé pour l'email."
    )
    email_use_ssl: bool = Field(
        default=False,
        validation_alias="EMAIL_USE_SSL",
        description="Spécifie si SSL doit être utilisé pour l'email."
    )
    default_from_email: str = Field(
        default="noreply@interviewprep.local",
        validation_alias="DEFAULT_FROM_EMAIL",
        description="Adresse email utilisée par défaut comme expéditeur."
    )

    # Application
    app_name: str = Field(
        default="InterviewPrep API",
        validation_alias="APP_NAME",
        description="Nom formel de l'application."
    )
    app_version: str = Field(
        default="1.0.0",
        validation_alias="APP_VERSION",
        description="Version actuelle de l'application."
    )
    debug: bool = Field(
        default=True,
        validation_alias="DEBUG",
        description="Mode debug activé ou désactivé."
    )

    # Frontend
    frontend_url: List[AnyHttpUrl] = Field(
        default_factory=lambda: parse_frontend_urls(
            "http://localhost:3000,http://localhost:5173,http://localhost:8080,http://localhost:4000"
        ),
        validation_alias="FRONTEND_URL",
        description="Liste des URLs valides pour la configuration CORS."
    )

    # Serveur
    port: int = Field(
        default=8000,
        validation_alias="PORT",
        description="Port d'écoute du serveur d'application."
    )
    host: str = Field(
        default="0.0.0.0",
        validation_alias="HOST",
        description="Adresse IP d'écoute de l'application."
    )

    # Stockage local des images
    upload_dir: str = Field(
        default="images/",
        validation_alias="UPLOAD_DIR",
        description="Chemin local du dossier stockant les fichiers uploadés."
    )
    upload_base_url: str = Field(
        default="",
        validation_alias="UPLOAD_BASE_URL",
        description="URL de base publique pour accéder aux fichiers uploadés."
    )

    @field_validator("frontend_url", mode="before")
    @classmethod
    def parse_frontend_url_env(cls, value):
        """
        Intercepte et nettoie la valeur de FRONTEND_URL avant validation.

        Args:
            value: La valeur brute de l'environnement (str) ou une liste existante.

        Returns:
            La valeur convertie en liste compréhensible par le validateur Pydantic.
        """
        if isinstance(value, str):
            return parse_frontend_urls(value)
        return value

    @field_validator("debug", "email_use_tls", "email_use_ssl", mode="before")
    @classmethod
    def parse_bool(cls, value):
        """
        Convertit de manière permissive différentes chaînes en types booléens.

        Args:
            value: Une valeur str (comme "true", "1", "yes") ou bool.

        Returns:
            bool: La conversion stricte (True/False). Retourne la valeur de 
            départ si elle n'est ni booléenne ni de type str reconnu.
        """
        if isinstance(value, bool):
            return value
        if isinstance(value, str):
            lowered = value.strip().lower()
            if lowered in {"true", "1", "yes", "debug", "dev", "development"}:
                return True
            if lowered in {"false", "0", "no", "release", "prod", "production"}:
                return False
        return value

    def __init__(self, **kwargs):
        """
        Initialise l'instance des paramètres.
        
        Charge dynamiquement les identifiants de modèles OpenAI disponibles
        depuis les variables d'environnement OPENAI_MODEL_ID_1 à 12 et 
        détermine le modèle par défaut si celui-ci n'est pas spécifié.
        """
        super().__init__(**kwargs)
        self.openai_models = [
            os.getenv(f"OPENAI_MODEL_ID_{i}")
            for i in range(1, 13)
            if os.getenv(f"OPENAI_MODEL_ID_{i}")
        ]
        if not self.ai_primary_model:
            primary = os.getenv("OPENAI_MODEL_ID_1") or os.getenv("ANTHROPIC_MODEL")
            if primary:
                self.ai_primary_model = primary.strip()


# Instance globale des configurations (Singleton)
settings = Settings()
