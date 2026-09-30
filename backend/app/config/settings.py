"""
Module de configuration de l'application.
"""

import json
from typing import List

from pydantic import Field, field_validator, AliasChoices
from pydantic_settings import BaseSettings, SettingsConfigDict


def parse_frontend_urls(raw_value: str | None) -> list[str]:
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


# Fournisseurs compatibles avec l'API OpenAI : un simple changement de
# `AI_PROVIDER` suffit, sans réécrire le client. `AI_BASE_URL` reste prioritaire
# pour un endpoint personnalisé.
AI_PROVIDER_BASE_URLS = {
    "openai": "",
    "groq": "https://api.groq.com/openai/v1",
    "openrouter": "https://openrouter.ai/api/v1",
    "together": "https://api.together.xyz/v1",
    "cerebras": "https://api.cerebras.ai/v1",
    "deepseek": "https://api.deepseek.com/v1",
    "sambanova": "https://api.sambanova.ai/v1",
    "mistral": "https://api.mistral.ai/v1",
}

# Variables d'environnement dans lesquelles est stockée la clé de chaque
# fournisseur (lues via `extra="allow"`, donc absentes du schéma).
AI_PROVIDER_KEY_ALIASES = {
    "groq": "GROQ_API_KEY",
    "openrouter": "OPENROUTER_API_KEY",
    "together": "TOGETHER_API_KEY",
    "cerebras": "CEREBRAS_API_KEY",
    "deepseek": "DEEPSEEK_API_KEY",
    "sambanova": "SAMBANOVA_API_KEY",
    "mistral": "MISTRAL_API_KEY",
}


class Settings(BaseSettings):
    """
    Classe définissant les paramètres globaux de configuration.
    """

    model_config = SettingsConfigDict(env_file=".env", extra="allow")

    # Base de données (Postgres uniquement)
    database_url: str = Field(
        validation_alias="DATABASE_URL",
        description="L'URL de connexion à la base de données principale (Postgres)."
    )
    database_direct_url: str = Field(
        default="",
        validation_alias="DATABASE_DIRECT_URL",
        description="URL PostgreSQL directe utilisée par Alembic.",
    )
    database_pool_size: int = Field(default=5, validation_alias="DATABASE_POOL_SIZE")
    database_max_overflow: int = Field(default=5, validation_alias="DATABASE_MAX_OVERFLOW")
    redis_url: str = Field(
        default="redis://localhost:6379/0",
        validation_alias="REDIS_URL",
        description="L'URL de connexion à l'instance Redis."
    )

    # Sécurité JWT
    secret_key: str = Field(validation_alias="SECRET_KEY")
    access_token_expire_minutes: int = Field(validation_alias="ACCESS_TOKEN_EXPIRE_MINUTES")
    refresh_token_expire_minutes: int = Field(validation_alias="REFRESH_TOKEN_EXPIRE_MINUTES")
    algorithm: str = Field(default="HS256", validation_alias="ALGORITHM")

    # Rate Limiting
    max_attempts: int = Field(default=5, validation_alias="MAX_ATTEMPTS")
    lockout_time: int = Field(default=300, validation_alias="LOCKOUT_TIME")

    # AI providers
    # `ai_provider` était déclaré mais jamais consommé par le code : le client
    # était câblé en dur sur OpenAI. Les paramètres ci-dessous rendent le
    # fournisseur réellement pilotable par l'environnement.
    # `openai_api_key` n'est plus obligatoire : avec `AI_PROVIDER=groq` (par
    # exemple), c'est `GROQ_API_KEY` qui porte la clé active.
    openai_api_key: str = Field(default="", validation_alias="OPENAI_API_KEY")
    ai_provider: str = Field(default="openai", validation_alias="AI_PROVIDER")
    ai_base_url: str = Field(default="", validation_alias="AI_BASE_URL")
    ai_api_key: str = Field(default="", validation_alias="AI_API_KEY")
    ai_fallback_base_url: str = Field(default="", validation_alias="AI_FALLBACK_BASE_URL")
    ai_fallback_api_key: str = Field(default="", validation_alias="AI_FALLBACK_API_KEY")
    ai_max_retries: int = Field(default=1, validation_alias="AI_MAX_RETRIES")
    ai_quota_circuit_threshold: int = Field(default=3, validation_alias="AI_QUOTA_CIRCUIT_THRESHOLD")
    ai_quota_circuit_cooldown_seconds: int = Field(default=120, validation_alias="AI_QUOTA_CIRCUIT_COOLDOWN_SECONDS")
    ai_primary_model: str = Field(validation_alias="AI_PRIMARY_MODEL")
    ai_fallback_model: str = Field(validation_alias="AI_FALLBACK_MODEL")

    @property
    def extra_env(self) -> dict:
        """Variables d'environnement connues mais hors schéma (`extra="allow"`)."""
        return {key.upper(): str(value) for key, value in (self.model_extra or {}).items()}

    @property
    def resolved_ai_provider(self) -> str:
        return (self.ai_provider or "openai").strip().lower()

    @property
    def resolved_ai_base_url(self) -> str:
        if self.ai_base_url:
            return self.ai_base_url
        return AI_PROVIDER_BASE_URLS.get(self.resolved_ai_provider, "")

    @property
    def resolved_ai_api_key(self) -> str:
        """Clé du fournisseur actif : AI_API_KEY, puis celle du preset, puis OPENAI_API_KEY."""
        if self.ai_api_key:
            return self.ai_api_key
        alias = AI_PROVIDER_KEY_ALIASES.get(self.resolved_ai_provider)
        if alias:
            provider_key = self.extra_env.get(alias, "")
            if provider_key:
                return provider_key
        return self.openai_api_key

    @property
    def ai_has_fallback_provider(self) -> bool:
        """Vrai si un fournisseur de secours réellement distinct est configuré."""
        return bool(self.ai_fallback_api_key and self.ai_fallback_base_url)

    # AI feature toggles
    ai_feature_generate_exercises: bool = Field(default=True, validation_alias="AI_FEATURE_GENERATE_EXERCISES")
    ai_feature_transcribe_audio: bool = Field(default=True, validation_alias="AI_FEATURE_TRANSCRIBE_AUDIO")

    # Email — SMTP, unique transport.
    # Le port 587 (soumission authentifiée, STARTTLS) est le port IANA standard.
    # Le port 25 est bloqué par tous les hébergeurs cloud, ports 465 et 587
    # également sur le free tier de Render — d'où le choix d'un plan payant.
    email_timeout_seconds: float = Field(
        default=8.0,
        validation_alias=AliasChoices("EMAIL_TIMEOUT_SECONDS", "EMAIL_HTTP_TIMEOUT_SECONDS"),
    )

    email_host: str = Field(default="smtp.gmail.com", validation_alias="SMTP_HOST")
    email_port: int = Field(default=587, validation_alias="SMTP_PORT")
    email_username: str = Field(default="", validation_alias=AliasChoices("SMTP_USER", "EMAIL_USERNAME"))
    email_password: str = Field(default="", validation_alias=AliasChoices("SMTP_PASSWORD", "EMAIL_PASSWORD"))
    email_use_tls: bool = Field(default=True, validation_alias="EMAIL_USE_TLS")
    email_use_ssl: bool = Field(default=False, validation_alias="EMAIL_USE_SSL")

    # Gmail refuse l'authentification par mot de passe du compte : il faut un
    # mot de passe d'application à 16 caractères
    # (Compte Google → Sécurité → Validation en 2 étapes → Mots de passe
    # d'application). Un mauvais mot de passe produit un 535, classé permanent :
    # aucun retry, échec remonté immédiatement.
    default_from_email: str = Field(default="", validation_alias="DEFAULT_FROM_EMAIL")
    google_client_id: str = Field(default="", validation_alias="GOOGLE_CLIENT_ID")
    email_otp_ttl_minutes: int = Field(default=10, validation_alias="EMAIL_OTP_TTL_MINUTES")
    email_otp_max_attempts: int = Field(default=5, validation_alias="EMAIL_OTP_MAX_ATTEMPTS")
    email_2fa_enabled: bool = Field(default=False, validation_alias="EMAIL_2FA_ENABLED")
    email_2fa_otp_ttl_minutes: int = Field(default=10, validation_alias="EMAIL_2FA_OTP_TTL_MINUTES")
    password_reset_code_ttl_minutes: int = Field(
        default=30, validation_alias="PASSWORD_RESET_CODE_TTL_MINUTES"
    )

    # Application
    app_name: str = Field(default="InterviewPrep API", validation_alias="APP_NAME")
    app_version: str = Field(default="2.1.3", validation_alias="APP_VERSION")
    debug: bool = Field(default=False, validation_alias="DEBUG")
    app_environment: str = Field(default="development", validation_alias="APP_ENVIRONMENT")
    backend_api_key: str = Field(default="", validation_alias="BACKEND_API_KEY")

    # Frontend
    frontend_url: str = Field(
        default="http://localhost:3000",
        validation_alias="FRONTEND_URL",
        description="Origines CORS du frontend : URL unique, liste JSON ou liste séparée par des virgules.",
    )

    @field_validator("frontend_url", mode="before")
    @classmethod
    def _normalize_frontend_url(cls, value: object) -> str:
        if value is None:
            return "http://localhost:3000"
        if isinstance(value, list):
            return ", ".join(str(v).strip() for v in value if str(v).strip())
        return str(value).strip() or "http://localhost:3000"

    @property
    def frontend_origins(self) -> List[str]:
        """Origines CORS normalisées (URL unique, JSON ou CSV)."""
        return parse_frontend_urls(self.frontend_url)

    @property
    def email_configured(self) -> bool:
        """Vrai si le transport SMTP dispose de ses identifiants.

        `default_from_email` est exigé : un émetteur absent fait échouer la
        session SMTP au moment de l'envoi, bien plus tard et bien plus
        obscurément qu'un contrôle ici.
        """
        return bool(
            self.default_from_email and self.email_username and self.email_password
        )

    # Serveur
    port: int = Field(default=8000, validation_alias="PORT")
    host: str = Field(default="0.0.0.0", validation_alias="HOST")

    # Stockage
    upload_dir: str = Field(default="/app/media", validation_alias="UPLOAD_DIR")
    upload_base_url: str = Field(
        default="",
        validation_alias="UPLOAD_BASE_URL",
        description="URL de base du stockage local (uniquement utilisé avec STORAGE_PROVIDER=local).",
    )
    storage_provider: str = Field(default="local", validation_alias="STORAGE_PROVIDER")
    max_upload_bytes: int = Field(
        default=5 * 1024 * 1024,
        validation_alias="MAX_UPLOAD_BYTES",
        description="Taille maximale d'un fichier téléversé (octets).",
    )

    # Stockage S3
    s3_access_key: str = Field(default="", validation_alias="S3_ACCESS_KEY")
    s3_secret_key: str = Field(default="", validation_alias="S3_SECRET_KEY")
    s3_region: str = Field(default="", validation_alias="S3_REGION")
    s3_endpoint: str = Field(default="", validation_alias="S3_ENDPOINT")
    s3_bucket: str = Field(default="", validation_alias="S3_BUCKET")

    # Stockage Azure
    azure_connection_string: str = Field(default="", validation_alias="AZURE_CONNECTION_STRING")
    azure_container: str = Field(default="", validation_alias="AZURE_CONTAINER")

    # Stockage Cloudinary
    cloudinary_cloud_name: str = Field(default="", validation_alias="CLOUDINARY_CLOUD_NAME")
    cloudinary_api_key: str = Field(default="", validation_alias="CLOUDINARY_API_KEY")
    cloudinary_api_secret: str = Field(default="", validation_alias="CLOUDINARY_API_SECRET")
    cloudinary_folder: str = Field(default="interviewprep/avatars", validation_alias="CLOUDINARY_FOLDER")

    @property
    def openai_models(self) -> List[str]:
        """Modèles proposés au sélecteur du frontend.

        Accepte les deux préfixes historiques : `AI_MODEL_ID_*` (utilisé par
        les configurations Groq) et `OPENAI_MODEL_ID_*`. Avant, seule la
        seconde forme était lue : une config Groq exposait les modèles OpenAI
        par défaut au frontend.
        """
        models: list[str] = []
        prefixes = ("AI_MODEL_ID_", "OPENAI_MODEL_ID_")
        for key, value in sorted(self.extra_env.items()):
            if not value:
                continue
            if any(key.startswith(prefix) for prefix in prefixes):
                model = value.strip()
                if model and model not in models:
                    models.append(model)
        if not models:
            if self.ai_primary_model:
                models.append(self.ai_primary_model)
            if self.ai_fallback_model and self.ai_fallback_model not in models:
                models.append(self.ai_fallback_model)
            if not models:
                models = ["gpt-4o", "gpt-4o-mini", "gpt-3.5-turbo"]
        return models


settings = Settings()
