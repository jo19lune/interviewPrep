import hmac

from fastapi import Request
from fastapi.responses import JSONResponse

from app.config.settings import settings


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
