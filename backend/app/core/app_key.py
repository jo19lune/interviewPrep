import hmac
import logging

from fastapi import Request
from fastapi.responses import JSONResponse

from app.config.settings import settings

logger = logging.getLogger(__name__)


async def verify_backend_api_key(request: Request, call_next):
    if not request.url.path.startswith("/api/v1"):
        return await call_next(request)
    if request.method == "OPTIONS":
        return await call_next(request)

    if not settings.backend_api_key:
        if settings.app_environment.lower() in {"production", "staging"}:
            return JSONResponse(
                status_code=503,
                content={"detail": "Backend API key is not configured"},
            )
        return await call_next(request)

    provided_key = request.headers.get("X-API-Key", "")
    if not hmac.compare_digest(provided_key, settings.backend_api_key):
        return JSONResponse(
            status_code=401,
            content={"detail": "Invalid application key"},
        )

    return await call_next(request)


def validate_production_application_key() -> None:
    if (
        settings.app_environment.lower() in {"production", "staging"}
        and not settings.backend_api_key
    ):
        raise RuntimeError(
            "BACKEND_API_KEY must be configured in production and staging"
        )


def validate_ai_configuration() -> None:
    """Vérifie qu'une clé IA est résolvable au démarrage.

    `OPENAI_API_KEY` n'est plus obligatoire dans le schéma (avec
    `AI_PROVIDER=groq`, c'est `GROQ_API_KEY` qui porte la clé) : sans cette
    vérification, une clé absente ne se révèle qu'à la première requête, sous
    forme d'un « No AI client configured » opaque.
    """
    if settings.resolved_ai_api_key:
        logger.info(
            "AI provider resolved: %s (base_url=%s)",
            settings.resolved_ai_provider,
            settings.resolved_ai_base_url or "openai (default)",
        )
        return

    message = (
        f"No API key for AI provider '{settings.resolved_ai_provider}'. Set "
        "AI_API_KEY, the provider-specific key (GROQ_API_KEY, "
        "OPENROUTER_API_KEY, …) or OPENAI_API_KEY."
    )
    if settings.app_environment.lower() in {"production", "staging"}:
        raise RuntimeError(message)
    logger.warning(message)
