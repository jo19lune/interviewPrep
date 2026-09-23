# ⚙️ InterviewPrep - Backend (FastAPI)

Ce répertoire contient le code source du backend de l'application **InterviewPrep**. Il est construit avec Python et le framework **FastAPI**.

## 🏗️ Architecture

Le backend suit une architecture modulaire pour séparer les préoccupations :

* **`app/main.py`** : Point d'entrée de l'application FastAPI.
* **`app/routers/`** : Définition des endpoints de l'API (authentification, dashboard, exercices, profil, simulation).
* **`app/services/`** : Logique métier et appels externes (IA, emails).
* **`app/models/`** : Modèles SQLAlchemy représentant les tables de la base de données.
* **`app/schemas/`** : Modèles Pydantic pour la validation des données d'entrée/sortie.
* **`app/core/`** : Configuration centrale, sécurité et utilitaires.
* **`app/data/`** : Gestion de la base de données et scripts de seed.

### Feedback IA des tests QA

`POST /api/v1/qa/feedback` nécessite un token Bearer valide. Le backend calcule
la note à partir des réponses utilisateur, demande à l'IA les points forts,
axes d'amélioration et recommandations, puis sauvegarde un snapshot dans
`qa_feedbacks`. La réponse contient `id`, `score_global`, `points_forts`,
`ameliorations`, `recommandations` et `genere_le`.

Appliquer la migration avant le démarrage en production :

```bash
alembic upgrade head
```

## 📋 Prérequis

* **Python** 3.9 ou supérieur
* **PostgreSQL** (ou SQLite pour le développement local rapide)
* **Docker** et **Docker Compose** (optionnel, mais recommandé)

## 🛠️ Installation et Configuration

1. **Créer un environnement virtuel**

   ```bash
   python -m venv venv
   ```

2. **Activer l'environnement virtuel**

   * Sous Linux/macOS : `source venv/bin/activate`
   * Sous Windows : `venv\Scripts\activate`

3. **Installer les dépendances**

   ```bash
   pip install -r requirements.txt
   ```

4. **Configuration des variables d'environnement**

   Copiez le fichier d'exemple et remplissez vos informations :

   ```bash
   cp .env.example .env
   ```

   Assurez-vous de configurer correctement les clés secrètes, l'URL de la base de données, et les éventuelles clés d'API externes (IA).

## 🚀 Lancer le Serveur

### Sans Docker (Développement local)

Assurez-vous que votre base de données est accessible et que `.env` est correctement configuré.

```bash
uvicorn app.main:app --reload
```

L'API sera accessible sur `http://127.0.0.1:8000`. Vous pouvez consulter la documentation interactive Swagger à l'adresse `http://127.0.0.1:8000/docs`.

### Avec Docker (Recommandé)

Si vous avez Docker installé, vous pouvez démarrer l'ensemble des services (base de données + backend) très facilement :

```bash
docker-compose up -d --build
```

## 🧪 Exécuter les Tests

Pour lancer la suite de tests automatisés (basée sur `pytest`) :

```bash
pytest
```

## 🔐 Contrats d'authentification Flutter

Tous les endpoints sont préfixés par `/api/v1`.

* `POST /auth/google` — body `{ "id_token": "..." }`. Le serveur vérifie la
  signature, l'émetteur, l'expiration, l'audience (`GOOGLE_CLIENT_ID`) et
  `email_verified`, puis crée ou lie le compte par email.
* `POST /auth/login` — body `{ "courriel", "mot_de_passe" }`. Avec
  `EMAIL_2FA_ENABLED=true`, la réponse est `{ "requires_2fa": true,
  "challenge_expires_in_seconds", "user" }`; aucun token n'est délivré.
* `POST /auth/login/verify-otp` — body `{ "courriel", "code" }`; consomme le
  code et retourne `access_token`, `refresh_token` et `user`.
* `POST /auth/forgot-password` — réponse volontairement non révélatrice;
  `POST /auth/verify-reset-code` vérifie sans consommer, puis
  `POST /auth/reset-password` consomme le code et change le mot de passe.

Les OTP sont hachés en base, expirent, sont limités en tentatives et ne sont
utilisables qu'une seule fois. Les emails sont envoyés via `BackgroundTasks`
avec logs et trois tentatives SMTP par défaut.

## Stockage Cloudinary des avatars

Pour activer Cloudinary, définir `STORAGE_PROVIDER=cloudinary` et renseigner
les variables suivantes dans l'environnement du backend :

```env
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
CLOUDINARY_FOLDER=interviewprep/avatars
```

Après ajout de ces variables, appliquer `alembic upgrade head`. L'endpoint
`PUT /api/v1/profile/avatar` conserve son contrat multipart : le backend
envoie l'image à Cloudinary, la redimensionne pour un avatar et utilise le
format WebP explicite (`f_webp`). L'ancien avatar est supprimé avec son
`public_id`.
