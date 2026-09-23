"""
Module de configuration de l'application.
"""

import json
from typing import List

from pydantic import AnyHttpUrl, Field, field_validator, AliasChoices
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
    openai_api_key: str = Field(validation_alias="OPENAI_API_KEY")
    ai_provider: str = Field(default="openai", validation_alias="AI_PROVIDER")
    ai_primary_model: str = Field(validation_alias="AI_PRIMARY_MODEL")
    ai_fallback_model: str = Field(validation_alias="AI_FALLBACK_MODEL")

    # AI feature toggles
    ai_feature_generate_exercises: bool = Field(default=True, validation_alias="AI_FEATURE_GENERATE_EXERCISES")
    ai_feature_transcribe_audio: bool = Field(default=True, validation_alias="AI_FEATURE_TRANSCRIBE_AUDIO")

    # Email
    email_host: str = Field(default="smtp.gmail.com", validation_alias="SMTP_HOST")
    email_port: int = Field(default=587, validation_alias="SMTP_PORT")
    email_username: str = Field(default="", validation_alias=AliasChoices("SMTP_USER", "EMAIL_USERNAME"))
    email_password: str = Field(default="", validation_alias=AliasChoices("SMTP_PASSWORD", "EMAIL_PASSWORD"))
    email_use_tls: bool = Field(default=True, validation_alias="EMAIL_USE_TLS")
    email_use_ssl: bool = Field(default=False, validation_alias="EMAIL_USE_SSL")
    default_from_email: str = Field(default="", validation_alias="DEFAULT_FROM_EMAIL")
    google_client_id: str = Field(default="", validation_alias="GOOGLE_CLIENT_ID")
    email_otp_ttl_minutes: int = Field(default=10, validation_alias="EMAIL_OTP_TTL_MINUTES")
    email_otp_max_attempts: int = Field(default=5, validation_alias="EMAIL_OTP_MAX_ATTEMPTS")
    email_2fa_enabled: bool = Field(default=False, validation_alias="EMAIL_2FA_ENABLED")
    email_2fa_otp_ttl_minutes: int = Field(default=10, validation_alias="EMAIL_2FA_OTP_TTL_MINUTES")

    # Application
    app_name: str = Field(default="InterviewPrep API", validation_alias="APP_NAME")
    app_version: str = Field(default="1.0.0", validation_alias="APP_VERSION")
    debug: bool = Field(default=False, validation_alias="DEBUG")

    # Frontend
    frontend_url: List[AnyHttpUrl] = Field(
        default_factory=lambda: parse_frontend_urls("http://localhost:3000"),
        validation_alias="FRONTEND_URL"
    )

    # Serveur
    port: int = Field(default=8000, validation_alias="PORT")
    host: str = Field(default="0.0.0.0", validation_alias="HOST")

    # Stockage
    upload_dir: str = Field(default="/app/media", validation_alias="UPLOAD_DIR")
    upload_base_url: str = Field(validation_alias="UPLOAD_BASE_URL")
    storage_provider: str = Field(default="local", validation_alias="STORAGE_PROVIDER")

    # Stockage S3
    s3_access_key: str = Field(default="", validation_alias="S3_ACCESS_KEY")
    s3_secret_key: str = Field(default="", validation_alias="S3_SECRET_KEY")
    s3_region: str = Field(default="", validation_alias="S3_REGION")
    s3_endpoint: str = Field(default="", validation_alias="S3_ENDPOINT")
    s3_bucket: str = Field(default="", validation_alias="S3_BUCKET")

    # Stockage Azure
    azure_connection_string: str = Field(default="", validation_alias="AZURE_CONNECTION_STRING")
    azure_container: str = Field(default="", validation_alias="AZURE_CONTAINER")

    @property
    def openai_models(self) -> List[str]:
        models = []
        if self.model_extra:
            for key, value in self.model_extra.items():
                if key.upper().startswith("OPENAI_MODEL_ID_") and value:
                    models.append(str(value))
        if not models:
            if self.ai_primary_model:
                models.append(self.ai_primary_model)
            if self.ai_fallback_model and self.ai_fallback_model not in models:
                models.append(self.ai_fallback_model)
            if not models:
                models = ["gpt-4o", "gpt-4o-mini", "gpt-3.5-turbo"]
        return models


settings = Settings()
