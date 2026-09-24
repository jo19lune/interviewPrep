# ============================================================
# InterviewPrep API — Image de production 2.0.0 (Render)
# Multi-stage : builder (dépendances) -> runtime (minimal)
# ============================================================

# ---------------- Étape 1 : Build ----------------
FROM python:3.11-slim AS builder

WORKDIR /app

# Dépendances système nécessaires à la compilation (psycopg2/asyncpg)
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# ---------------- Étape 2 : Runtime ----------------
FROM python:3.11-slim

WORKDIR /app

# libpq5 (psycopg2 au runtime) + curl (healthcheck Docker)
RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq5 curl \
    && rm -rf /var/lib/apt/lists/*

# Interpréteur + dépendances Python installées au build
COPY --from=builder /usr/local /usr/local

# Code applicatif (migrations/, alembic.ini, app/… voir .dockerignore)
COPY . .

# Utilisateur non-root (sécurité). UPLOAD_DIR /app/media reste ouvrable.
RUN addgroup --system app \
    && adduser --system --ingroup app appuser \
    && mkdir -p /app/media \
    && chown -R appuser:app /app

# Entrypoint : migrations Alembic puis uvicorn
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Port injecté par Render (default 10000) ; 1 worker/instance suffit (app async,
# Render monte en charge par instances via l'autoscaling).
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    APP_ENVIRONMENT=production \
    PORT=10000 \
    WORKERS=1

USER appuser

EXPOSE 10000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -fsS "http://127.0.0.1:${PORT:-10000}/health" || exit 1

ENTRYPOINT ["docker-entrypoint.sh"]