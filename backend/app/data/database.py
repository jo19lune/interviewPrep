"""
Configuration et gestion de la base de données (Postgres uniquement).
"""

import logging
from sqlalchemy.engine import make_url
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.config.settings import settings
from app.models.base import Base
from app.models.email_otp import EmailOTP  # noqa: F401

logger = logging.getLogger(__name__)

def normalize_async_database_url(database_url: str) -> str:
    """Normalize Render/Neon URLs for SQLAlchemy's asyncpg dialect."""
    if database_url.startswith("postgres://"):
        database_url = "postgresql://" + database_url[len("postgres://"):]
    if database_url.startswith("postgresql://"):
        database_url = "postgresql+asyncpg://" + database_url[len("postgresql://"):]
    if database_url.startswith("postgresql+psycopg://"):
        database_url = "postgresql+asyncpg://" + database_url[len("postgresql+psycopg://"):]

    url = make_url(database_url)
    if url.drivername != "sqlite+aiosqlite" and not url.drivername.endswith("+asyncpg"):
        raise ValueError(
            "DATABASE_URL must use PostgreSQL asyncpg or SQLite aiosqlite"
        )
    if url.drivername.endswith("+asyncpg"):
        query = dict(url.query)
        if query.get("sslmode") == "require":
            query["ssl"] = "require"
            query.pop("sslmode", None)
        # asyncpg (≤ 0.31) n'accepte pas channel_binding ; Neon l'ajoute parfois
        # dans l'URL copiée → SQLAlchemy le forward en kwarg → TypeError.
        query.pop("channel_binding", None)
        url = url.set(query=query)
    return url.render_as_string(hide_password=False)


database_url = normalize_async_database_url(settings.database_url)
engine_kwargs = {
    "echo": settings.debug,
    "pool_pre_ping": True,
}
if not database_url.startswith("sqlite"):
    engine_kwargs.update(
        pool_size=settings.database_pool_size,
        max_overflow=settings.database_max_overflow,
    )

# Création du moteur async Postgres
engine = create_async_engine(database_url, **engine_kwargs)

# Session async
AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


async def get_db() -> AsyncSession:
    """Obtenir une session de base de données async."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db():
    """Initialiser la base de données (création des tables)."""
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Error initializing database: {e}")
        raise


async def close_db():
    """Fermer les connexions à la base de données."""
    await engine.dispose()
    logger.info("Database connections closed")
