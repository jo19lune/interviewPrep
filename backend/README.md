# Backend InterviewPrep - Documentation

## Vue d'ensemble

Backend FastAPI pour la plateforme InterviewPrep - application mobile de préparation aux entretiens d'embauche avec simulation IA.

Stack technique:
- **Framework**: FastAPI (asynchrone, haute performance)
- **BD**: PostgreSQL avec SQLAlchemy 2.0 ORM
- **Authentification**: JWT
- **IA**: OpenAI / Claude via configuration de modèle
- **Serveur**: Uvicorn

## Installation & Setup

### Prérequis
- Python 3.10+
- PostgreSQL 12+
- Redis (optionnel)

### 1. Se placer dans le dossier backend
```bash
cd backend
```

### 2. Créer et activer l'environnement virtuel
```bash
python -m venv venv
venv\Scripts\activate  # Sur Linux/macOS: source venv/bin/activate
```

### 3. Installer les dépendances
```bash
pip install -r requirements.txt
```

### 4. Configurer les variables d'environnement
```bash
copy .env.example .env
```

Puis éditez `.env` et remplissez les valeurs.

### Variables clés
- `DATABASE_URL`: URL PostgreSQL (par exemple `postgresql+asyncpg://postgres:postgres@localhost:5432/interviewprep`)
- `SECRET_KEY`: clé secrète JWT
- `OPENAI_API_KEY`: clé API OpenAI / Claude
- `OPENAI_MODEL_ID_1`: modèle par défaut utilisé par l'IA
- `FRONTEND_URL`: origines CORS autorisées séparées par des virgules
- `HOST`: adresse d'écoute (par défaut `0.0.0.0`)
- `PORT`: port d'écoute (par défaut `8000`)

### 5. Initialiser la base de données
Le projet contient un dossier `migrations/` pour Alembic.
```bash
alembic upgrade head
```

### 6. Démarrer le serveur
```bash
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 9000
```

L'API sera disponible sur `http://localhost:9000` si `PORT=9000` est configuré.

## Documentation API

### Interface interactive
- **Swagger UI**: `http://localhost:9000/docs`
- **ReDoc**: `http://localhost:9000/redoc`

### Endpoints principaux

#### Authentification (`/auth`)
- `POST /auth/register` - créer un compte
- `POST /auth/login` - se connecter
- `POST /auth/refresh` - rafraîchir le token
- `GET /auth/me` - récupérer l'utilisateur courant
- `DELETE /auth/me` - supprimer le compte

#### Profil (`/profile`)
- `GET /profile/me` - récupérer le profil courant
- `PUT /profile/update` - mettre à jour le profil
- `PUT /profile/avatar` - upload d'avatar (non implémenté)

#### Exercices (`/exercises`)
- `GET /exercises` - lister les exercices
- `GET /exercises/{id}` - récupérer un exercice
- `GET /exercises/random/get` - récupérer un exercice aléatoire
- `POST /exercises` - créer un exercice (admin check TODO)

#### Simulation (`/simulation`)
- `POST /simulation/start` - démarrer une simulation
- `POST /simulation/answer` - soumettre une réponse
- `GET /simulation/stream/{session_id}` - streaming SSE (non implémenté)
- `POST /simulation/finish/{session_id}` - terminer la simulation

#### Progression (`/progress`)
- `GET /progress/me` - progression personnelle
- `GET /progress/stats` - statistiques détaillées
- `GET /progress/history` - historique des sessions
- `GET /progress/export` - export PDF (non implémenté)

### Routes utilitaires
- `GET /health` - état de l'API
- `GET /` - informations de base

## Architecture

### Structure des dossiers
```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── config/
│   │   └── settings.py
│   ├── core/
│   ├── data/
│   ├── models/
│   ├── routers/
│   ├── schemas/
│   └── services/
├── migrations/
├── tests/
├── .env.example
├── requirements.txt
└── README.md
```

## Configuration actuelle

### Exemple `.env`
```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=interviewprep
DATABASE_URL=postgresql+asyncpg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
REDIS_URL=redis://redis:6379/0
SECRET_KEY=your_secret_key
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_MINUTES=1440
ALGORITHM=HS256
OPENAI_API_KEY=your_openai_api_key
OPENAI_MODEL_ID_1=gpt-5.5
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USERNAME=your-email@gmail.com
EMAIL_PASSWORD=your-email-password
EMAIL_USE_TLS=True
EMAIL_USE_SSL=False
DEFAULT_FROM_EMAIL=noreply@interviewprep.com
APP_NAME=InterviewPrep API
APP_VERSION=1.0.0
DEBUG=True
FRONTEND_URL=http://localhost:3000,http://localhost:5173
HOST=0.0.0.0
PORT=9000
UPLOAD_DIR=uploads/
UPLOAD_BASE_URL=http://localhost:9000/uploads/
```

### Notes importantes
- `FRONTEND_URL` doit contenir les origines CORS séparées par des virgules.
- `PORT` est défini dans `.env`; si absent, il retombe sur `8000`.
- `OPENAI_MODEL_ID_x` est utilisé pour construire dynamiquement la liste des modèles.

## Limitations actuelles
- `PUT /profile/avatar` n'est pas implémenté.
- `POST /exercises` ne vérifie pas encore les droits admin.
- `GET /simulation/stream/{session_id}` n'est pas opérationnel.
- `GET /progress/export` ne génère pas de PDF.
- `GET /progress/stats` est implémenté mais le regroupement par domaine est partiel.

## Tests

```bash
pytest
pytest tests/test_auth.py -v
```

## Support

Pour tout bug ou question, utilisez le repository GitHub ou créez une issue.


Logs structurés en JSON (en production). Les erreurs sont trackées avec:
- Niveau: DEBUG, INFO, WARNING, ERROR
- Format: timestamp, logger, level, message

À intégrer avec Sentry pour monitoring en production.

## Problèmes courants

### `ImportError: No module named 'app'`
Assurez-vous que vous vous trouvez dans le répertoire `backend/` et que l'environnement virtuel est activé.

### `Connection refused` (PostgreSQL)
Vérifiez que PostgreSQL est en cours d'exécution et que `DATABASE_URL` dans `.env` est correcte.

### `CORS error`
Vérifiez que le frontend URL est dans la liste `FRONTEND_URL` du `.env`

## Ressources

- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [SQLAlchemy 2.0](https://docs.sqlalchemy.org/en/20/)
- [Pydantic](https://docs.pydantic.dev)
- [JWT.io](https://jwt.io)
- [Anthropic Claude API](https://www.anthropic.com)

## Support

Pour les questions ou bugs, créez une issue sur le repository GitHub.

---

**Version**: 1.0.0  
**Dernière mise à jour**: Mai 2025  
**Mainteneur**: Équipe InterviewPrep
