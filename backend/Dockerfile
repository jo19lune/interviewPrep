# Étape 1 : Build
FROM python:3.11-slim AS builder

WORKDIR /app

# Installer dépendances système (psycopg2, etc.)
RUN apt-get update && apt-get install -y build-essential libpq-dev && rm -rf /var/lib/apt/lists/*

# Installer dépendances Python
COPY requirements.txt .
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Étape 2 : Runtime
FROM python:3.11-slim

WORKDIR /app

# Copier uniquement le code et les dépendances
COPY --from=builder /usr/local /usr/local
COPY . .

# Variables d’environnement par défaut
ENV PYTHONUNBUFFERED=1 \
    UVICORN_WORKERS=4 \
    UVICORN_PORT=9000

# Commande de démarrage (prod)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "9000"]
