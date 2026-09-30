"""
Application FastAPI - point d'entrée principal.

Ce module initialise l'application FastAPI, configure le cycle de vie,
le logging, le middleware CORS, les gestionnaires d'exceptions et inclut
les différents routeurs de l'API.
"""

import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from app.config.settings import settings
from app.core.exceptions import AppException
from app.core.app_key import (
    validate_ai_configuration,
    validate_production_application_key,
    verify_backend_api_key,
)
from app.data.database import close_db, init_db
from app.routers import activity_history, auth, dashboard, exercices, password_reset, profile, simulation, simulation_audio, qa

logger = logging.getLogger(__name__)

# Configuration du logging
logging.basicConfig(
    level=logging.INFO if not settings.debug else logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Gère le cycle de vie de l'application FastAPI.

    Initialise la base de données et peuple les données par défaut (comme 
    les exercices) au démarrage. Ferme proprement les connexions à la base
    de données lors de l'arrêt de l'application.

    Args:
        app (FastAPI): L'instance de l'application FastAPI en cours d'exécution.

    Yields:
        None: Cède le contrôle à l'application pendant sa durée de vie.
    """
    # Startup
    try:
        validate_production_application_key()
        validate_ai_configuration()
        await init_db()
        logger.info("Database initialized")
        
        # Seeder les exercices par défaut
        from app.data.database import AsyncSessionLocal
        from app.data.seeder import seed_exercises
        async with AsyncSessionLocal() as db:
            await seed_exercises(db)
            
    except Exception as e:
        logger.error(f"Failed to initialize or seed database: {e}")
        raise
    
    yield
    
    # Shutdown
    try:
        await close_db()
        logger.info("Database connections closed")
    except Exception as e:
        logger.error(f"Error closing database: {e}")


# Créer l'application FastAPI
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="API Backend InterviewPrep - Préparation aux entretiens d'embauche avec simulation IA",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

app.middleware("http")(verify_backend_api_key)

# Montage du répertoire d'upload pour servir les avatars
upload_dir = os.path.abspath(settings.upload_dir)
os.makedirs(upload_dir, exist_ok=True)
app.mount("/media", StaticFiles(directory=upload_dir), name="uploads-media")

# Configuration CORS (Accepte tous les frontends et appareils)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.frontend_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Exception handlers
@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
    """
    Gestionnaire global pour les exceptions personnalisées AppException.

    Intercepte les erreurs métier et les formate en réponses JSON structurées.

    Args:
        request (Request): La requête HTTP ayant déclenché l'exception.
        exc (AppException): L'exception de l'application interceptée.

    Returns:
        JSONResponse: Une réponse structurée contenant le message d'erreur et
        le code HTTP correspondant.
    """
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.message},
    )


# Health check
@app.get("/health", tags=["health"])
async def health_check() -> dict:
    """
    Vérifie l'état de l'API.

    Endpoint de diagnostic : expose la configuration résolue des intégrations
    externes (transport d'email, fournisseur IA, stockage). Les secrets ne sont
    jamais renvoyés — seule la présence des identifiants l'est. C'est ce qui
    permet de distinguer « clé absente » de « service injoignable » sans
    fouiller les logs de déploiement.
    """
    return {
        "status": "ok",
        "version": settings.app_version,
        "integrations": {
            "email": {
                "configured": settings.email_configured,
                "host": settings.email_host,
                "port": settings.email_port,
                "from": settings.default_from_email or None,
            },
            "ai": {
                "provider": settings.resolved_ai_provider,
                "base_url": settings.resolved_ai_base_url or "https://api.openai.com/v1",
                "primary_model": settings.ai_primary_model,
                "fallback_model": settings.ai_fallback_model,
                "configured": bool(settings.resolved_ai_api_key),
                "fallback_provider": settings.ai_has_fallback_provider,
            },
            "storage": {
                "provider": settings.storage_provider,
                "cloudinary_cloud_name": settings.cloudinary_cloud_name or None,
                "configured": (
                    bool(
                        settings.cloudinary_cloud_name
                        and settings.cloudinary_api_key
                        and settings.cloudinary_api_secret
                    )
                    if settings.storage_provider == "cloudinary"
                    else True
                ),
            },
            "google_sign_in": bool(settings.google_client_id),
        },
    }


# Inclure les routers sous le préfixe /api/v1
API_V1_PREFIX = "/api/v1"
app.include_router(activity_history.router, prefix=API_V1_PREFIX)
app.include_router(auth.router, prefix=API_V1_PREFIX)
app.include_router(password_reset.router, prefix=API_V1_PREFIX)
app.include_router(profile.router, prefix=API_V1_PREFIX)
app.include_router(exercices.router, prefix=API_V1_PREFIX)
app.include_router(dashboard.router, prefix=API_V1_PREFIX)
app.include_router(simulation.router, prefix=API_V1_PREFIX)
app.include_router(simulation_audio.router, prefix=API_V1_PREFIX)
app.include_router(qa.router, prefix=API_V1_PREFIX)


# Info API
@app.get("/", tags=["info"])
async def root() -> dict[str, str]:
    """
    Fournit les informations de base de l'API.

    Point de terminaison principal retournant les métadonnées de l'application 
    et des liens utiles comme la documentation.

    Returns:
        dict[str, str]: Un dictionnaire avec le nom, la version et les endpoints vitaux.
    """
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "docs": "/docs",
        "health": "/health"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        workers=1 if settings.debug else 4
    )
