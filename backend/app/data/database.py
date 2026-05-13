"""Configuration et gestion de la base de données"""

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.config.settings import settings
from app.models.base import Base
import logging

logger = logging.getLogger(__name__)

# Créer le moteur async
engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,  # Afficher les requêtes SQL en développement
    pool_pre_ping=True,  # Vérifier les connexions avant utilisation
    pool_size=10,
    max_overflow=20,
)

# Créer la factory de sessions
AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


async def get_db() -> AsyncSession:
    """Obtenir une session de base de données async"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db():
    """Initialiser la base de données (créer toutes les tables)"""
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Error initializing database: {e}")
        raise


async def close_db():
    """Fermer les connexions à la base de données"""
    await engine.dispose()
    logger.info("Database connections closed")
