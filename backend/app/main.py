"""Application FastAPI - point d'entrée principal"""

from contextlib import asynccontextmanager
from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config.settings import settings
from app.data.database import init_db, close_db
from app.routers import auth
from app.core.exceptions import AppException
import logging

logger = logging.getLogger(__name__)

# Configuration du logging
logging.basicConfig(
    level=logging.INFO if not settings.debug else logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gérer le cycle de vie de l'application"""
    # Startup
    try:
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

# Configuration CORS
origins = [str(url).rstrip("/") for url in settings.frontend_url]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Exception handlers
@app.exception_handler(AppException)
async def app_exception_handler(request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.message},
    )


# Health check
@app.get("/health", tags=["health"])
async def health_check():
    """Vérifier l'état de l'API"""
    return {"status": "ok", "version": settings.app_version}


# Inclure les routers
from app.routers import profile, exercices, dashboard, simulation
app.include_router(auth.router)
app.include_router(profile.router)
app.include_router(exercices.router)
app.include_router(dashboard.router)
app.include_router(simulation.router)

# Info API
@app.get("/", tags=["info"])
async def root():
    """Information de l'API"""
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
