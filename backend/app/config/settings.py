import json
import os
from typing import List

from pydantic import AnyHttpUrl, Field, field_validator
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
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Base de donnees
    database_url: str = Field(
        default="sqlite+aiosqlite:///./interviewprep_dev.db",
        validation_alias="DATABASE_URL",
    )
    redis_url: str = Field(default="redis://localhost:6379/0", validation_alias="REDIS_URL")

    # Securite JWT
    secret_key: str = Field(default="dev-only-change-me", validation_alias="SECRET_KEY")
    access_token_expire_minutes: int = Field(default=15, validation_alias="ACCESS_TOKEN_EXPIRE_MINUTES")
    refresh_token_expire_minutes: int = Field(default=1440, validation_alias="REFRESH_TOKEN_EXPIRE_MINUTES")
    algorithm: str = Field(default="HS256", validation_alias="ALGORITHM")

    # AI providers
    anthropic_api_key: str = Field(default="", validation_alias="ANTHROPIC_API_KEY")
    openai_api_key: str = Field(default="", validation_alias="OPENAI_API_KEY")
    openai_models: List[str] = []
    ai_provider: str = Field(default="auto", validation_alias="AI_PROVIDER")
    ai_primary_model: str = Field(default="", validation_alias="AI_PRIMARY_MODEL")
    ai_fallback_model: str = Field(default="", validation_alias="AI_FALLBACK_MODEL")
    ai_feature_generate_exercises: bool = Field(default=True, validation_alias="AI_FEATURE_GENERATE_EXERCISES")
    ai_feature_generate_questions: bool = Field(default=True, validation_alias="AI_FEATURE_GENERATE_QUESTIONS")
    ai_feature_generate_feedback: bool = Field(default=True, validation_alias="AI_FEATURE_GENERATE_FEEDBACK")

    # Email
    email_host: str = Field(default="smtp.gmail.com", validation_alias="EMAIL_HOST")
    email_port: int = Field(default=587, validation_alias="EMAIL_PORT")
    email_username: str = Field(default="", validation_alias="EMAIL_USERNAME")
    email_password: str = Field(default="", validation_alias="EMAIL_PASSWORD")
    email_use_tls: bool = Field(default=True, validation_alias="EMAIL_USE_TLS")
    email_use_ssl: bool = Field(default=False, validation_alias="EMAIL_USE_SSL")
    default_from_email: str = Field(default="noreply@interviewprep.local", validation_alias="DEFAULT_FROM_EMAIL")

    # Application
    app_name: str = Field(default="InterviewPrep API", validation_alias="APP_NAME")
    app_version: str = Field(default="1.0.0", validation_alias="APP_VERSION")
    debug: bool = Field(default=True, validation_alias="DEBUG")

    # Frontend
    frontend_url: List[AnyHttpUrl] = Field(
        default_factory=lambda: parse_frontend_urls(
            "http://localhost:3000,http://localhost:5173,http://localhost:8080,http://localhost:4000"
        ),
        validation_alias="FRONTEND_URL",
    )

    # Serveur
    port: int = Field(default=8000, validation_alias="PORT")
    host: str = Field(default="0.0.0.0", validation_alias="HOST")

    # Stockage local des images
    upload_dir: str = Field(default="images/", validation_alias="UPLOAD_DIR")
    upload_base_url: str = Field(default="", validation_alias="UPLOAD_BASE_URL")

    @field_validator("frontend_url", mode="before")
    @classmethod
    def parse_frontend_url_env(cls, value):
        if isinstance(value, str):
            return parse_frontend_urls(value)
        return value

    @field_validator("debug", "email_use_tls", "email_use_ssl", mode="before")
    @classmethod
    def parse_bool(cls, value):
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


settings = Settings()
