# Backend InterviewPrep - Documentation

## Vue d'ensemble

Backend FastAPI pour la plateforme InterviewPrep - une application mobile de préparation aux entretiens d'embauche avec simulation IA.

Stack technique:
- **Framework**: FastAPI (asynchrone, haute performance)
- **BD**: PostgreSQL avec SQLAlchemy 2.0 ORM
- **Authentification**: JWT (Bcrypt + Python-JOSE)
- **IA**: Claude AI (Anthropic)
- **Serveur**: Uvicorn

## Installation & Setup

### Prérequis
- Python 3.10+
- PostgreSQL 12+
- Redis (optionnel, pour futures améliorations)

### 1. Cloner et naviguer dans le repo
```bash
cd backend
```

### 2. Créer un environnement virtuel
```bash
python -m venv venv
source venv/bin/activate  # Sur Windows: venv\Scripts\activate
```

### 3. Installer les dépendances
```bash
pip install -r requirements.txt
```

### 4. Configurer les variables d'environnement
```bash
cp .env.example .env
# Éditer .env et remplir les valeurs
```

Variables clés à configurer:
- `DATABASE_URL`: URL PostgreSQL (postgresql+asyncpg://user:password@localhost:5432/interviewprep)
- `SECRET_KEY`: Clé secrète pour JWT (changez en production!)
- `CLAUDE_API_KEY`: Clé API Anthropic Claude

### 5. Initialiser la base de données
```bash
# Alembic pour les migrations (si implémenté)
alembic upgrade head
```

### 6. Démarrer le serveur
```bash
# Développement
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Production
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

L'API sera disponible à `http://localhost:8000`

## Documentation API

### Accéder à la documentation interactive
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Endpoints principaux

#### Authentification (`/auth`)
- `POST /auth/register` - Créer un compte
- `POST /auth/login` - Se connecter
- `POST /auth/refresh` - Rafraîchir access token
- `GET /auth/me` - Récupérer infos utilisateur
- `DELETE /auth/me` - Supprimer le compte (RGPD)

#### Profil (`/profile`)
- `GET /profile/me` - Récupérer profil complet
- `PUT /profile/update` - Modifier profil
- `PUT /profile/avatar` - Uploader image de profil

#### Exercices (`/exercises`)
- `GET /exercises` - Lister exercices avec filtres
- `GET /exercises/{id}` - Détail d'un exercice
- `GET /exercises/random/get` - Exercice aléatoire
- `POST /exercises` - Créer exercice (admin)

#### Simulation IA (`/simulation`)
- `POST /simulation/start` - Démarrer une simulation
- `POST /simulation/answer` - Soumettre une réponse
- `GET /simulation/stream/{session_id}` - Streaming SSE
- `POST /simulation/finish/{session_id}` - Terminer et générer feedback

#### Progression (`/progress`)
- `GET /progress/me` - Statistiques générales
- `GET /progress/stats` - Statistiques par domaine
- `GET /progress/history` - Historique des sessions
- `GET /progress/export` - Exporter rapport PDF

## Architecture

### Structure des dossiers
```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # Application FastAPI
│   ├── config/
│   │   └── settings.py         # Configuration (variables d'env)
│   ├── core/
│   │   ├── enums.py            # Énumérations (Domaine, Niveau, etc.)
│   │   ├── exceptions.py       # Exceptions personnalisées
│   │   └── security.py         # JWT, extraction utilisateur
│   ├── data/
│   │   └── database.py         # Connexion & session BD
│   ├── models/
│   │   ├── base.py             # Classe de base
│   │   ├── user.py             # Modèle User
│   │   ├── exercice.py         # Modèle Exercice
│   │   ├── session.py          # Modèle Session
│   │   ├── progression.py      # Modèle Progression
│   │   ├── feedback.py         # Modèle Retour (Feedback)
│   │   └── ai_simulation.py    # Modèle SimulationIA
│   ├── schemas/
│   │   ├── user.py             # Schémas User (Pydantic)
│   │   ├── exercice.py         # Schémas Exercice
│   │   ├── session.py          # Schémas Session
│   │   └── feedback.py         # Schémas Feedback
│   ├── services/
│   │   ├── auth_service.py     # Logique auth (JWT, Bcrypt)
│   │   ├── ai_service.py       # Intégration Claude AI
│   │   └── stats_service.py    # Calculs statistiques
│   └── routers/
│       ├── auth.py             # Routes d'authentification
│       ├── profile.py          # Routes de profil
│       ├── exercices.py        # Routes d'exercices
│       ├── simulation.py       # Routes de simulation
│       └── dashboard.py        # Routes de progression
├── migrations/                 # Migrations Alembic
├── tests/                      # Tests unitaires/intégration
├── .env.example               # Variables d'env example
├── requirements.txt           # Dépendances Python
└── README.md                  # Cette doc
```

## Modèles de données

### User
```python
id: UUID (PK)
courriel: String (unique, indexed)
mot_de_passe_hash: String (Bcrypt)
prenom: String
nom: String
domaine: Enum (TECHNIQUE, COMPORTEMENTAL, etc.)
niveau: Enum (DEBUTANT, INTERMEDIAIRE, AVANCE, EXPERT)
est_actif: Boolean (default: True)
cree_le: DateTime
modifie_le: DateTime
```

### Exercice
```python
id: UUID (PK)
titre: String
description: String
domaine: String (indexed)
difficulte: String (indexed)
duree_sec: Integer (en secondes)
questions: JSONB (structure flexible)
etiquettes: JSONB (liste de tags)
cree_le: DateTime
```

### Session
```python
id: UUID (PK)
utilisateur_id: UUID (FK -> User)
exercice_id: UUID (FK -> Exercice)
commence_le: DateTime
termine_le: DateTime
statut: String (EN_COURS, TERMINEE, ABANDONNEE, etc.)
score: Float
reponses: JSONB (historique des réponses)
cree_le: DateTime
```

### Retour (Feedback)
```python
id: UUID (PK)
session_id: UUID (FK -> Session, unique)
score_global: Float
points_forts: JSONB
ameliorations: JSONB
recommandations: JSONB
genere_le: DateTime
```

## Authentification JWT

### Flow
1. **Register/Login**: Obtenir `access_token` (15 min) + `refresh_token` (7 jours)
2. **Request**: Inclure `Authorization: Bearer <access_token>` dans headers
3. **Refresh**: Utiliser `refresh_token` pour obtenir un nouveau `access_token`
4. **Logout**: Simplement supprimer le token côté client

### Sécurité
- Mots de passe hashés avec Bcrypt (sel automatique)
- Tokens signés avec HS256
- Validation stricte des tokens
- Récupération de l'utilisateur depuis BD à chaque requête

## Configuration & Déploiement

### Développement
```bash
DEBUG=True
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/interviewprep
```

### Production
```bash
DEBUG=False
DATABASE_URL=<prod-database-url>
SECRET_KEY=<strong-random-key>
```

### Docker
```bash
# Construire l'image
docker build -t interviewprep-backend .

# Lancer avec docker-compose
docker-compose up
```

### CORS
Par défaut, CORS est configuré pour:
- `http://localhost:3000` (développement Flutter Web)
- `http://localhost:5173` (développement Vite)

Modifier dans `app/main.py` pour production.

## Tests

```bash
# Lancer tous les tests
pytest

# Avec couverture
pytest --cov=app

# Tests spécifiques
pytest tests/test_auth.py -v
```

## Logs & Monitoring

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
