#!/bin/sh
# ============================================================
# InterviewPrep API — Entrypoint de production 2.0.0
# 1) Applique les migrations Alembic (avec retry : Neon peut
#    être temporairement indisponible au boot du conteneur)
# 2) Démarre uvicorn sur le port injecté par Render ($PORT)
# ============================================================
set -e

echo "==> InterviewPrep API — démarrage (prod)"

# ---------- 1) Migrations Alembic ----------
_attempt=0
_max_attempts=12
until alembic upgrade head; do
    _attempt=$((_attempt + 1))
    if [ "$_attempt" -ge "$_max_attempts" ]; then
        echo "!! Migrations Alembic échouées après $_max_attempts tentatives — arrêt." >&2
        exit 1
    fi
    echo "-> Base non prête, nouvelle tentative dans 5s ($_attempt/$_max_attempts)..."
    sleep 5
done
echo "==> Migrations Alembic appliquées."

# ---------- 2) Uvicorn ----------
echo "==> Démarrage uvicorn sur le port ${PORT:-10000} (workers=${WORKERS:-1})"
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-10000}" --workers "${WORKERS:-1}"