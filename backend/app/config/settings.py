import os
from pydantic_settings import BaseSettings
from typing import List
from pydantic import AnyHttpUrl


class Settings(BaseSettings):
    # Base de données
    database_url: str = os.getenv(
        "DATABASE_URL"
    )
    redis_url: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")

    # Sécurité JWT
    secret_key: str = os.getenv("SECRET_KEY")
    access_token_expire_minutes: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 15))
    refresh_token_expire_minutes: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_MINUTES", 1440))  # 24h
    algorithm: str = os.getenv("ALGORITHM", "HS256")

    # OpenAI
    openai_api_key: str = os.getenv("OPENAI_API_KEY", "")
    openai_models: List[str] = []  # Liste dynamique des modèles

    # Email
    email_host: str = os.getenv("EMAIL_HOST", "smtp.gmail.com")
    email_port: int = int(os.getenv("EMAIL_PORT", 587))
    email_username: str = os.getenv("EMAIL_USERNAME", "")
    email_password: str = os.getenv("EMAIL_PASSWORD", "")
    email_use_tls: bool = os.getenv("EMAIL_USE_TLS", "True").lower() in ["true", "1"]
    email_use_ssl: bool = os.getenv("EMAIL_USE_SSL", "False").lower() in ["true", "1"]
    default_from_email: str = os.getenv("DEFAULT_FROM_EMAIL")

    # Application
    app_name: str = os.getenv("APP_NAME", "InterviewPrep API")
    app_version: str = os.getenv("APP_VERSION", "1.0.0")
    debug: bool = os.getenv("DEBUG", "True").lower() in ["true", "1"]

    # Frontend
    frontend_url: List[AnyHttpUrl] = [
        url.strip()
        for url in os.getenv(
            "FRONTEND_URL", "http://localhost:3000"
        ).split(",")
    ]

    # Serveur
    port: int = int(os.getenv("PORT", 8000))
    host: str = os.getenv("HOST", "0.0.0.0")

    # Stockage local des images
    upload_dir: str = os.getenv("UPLOAD_DIR", "images/")
    upload_base_url: str = os.getenv("UPLOAD_BASE_URL", "")

    class Config:
        env_file = ".env"
        extra = "ignore"  # Ignore les variables non définies

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Récupère toutes les variables OPENAI_MODEL_ID_X si elles existent
        self.openai_models = [
            os.getenv(f"OPENAI_MODEL_ID_{i}")
            for i in range(1, 13)
            if os.getenv(f"OPENAI_MODEL_ID_{i}")
        ]


settings = Settings()
