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
  `email_verified`, puis crée ou lie le compte par email. La réponse suit le
  même schéma que `/auth/login` : avec `EMAIL_2FA_ENABLED=true`, elle renvoie
  `{ "requires_2fa": true, "challenge_expires_in_seconds", "user" }` sans
  token, et le client doit valider le code via `/auth/login/verify-otp`.
* `POST /auth/login` — body `{ "courriel", "mot_de_passe" }`. Avec
  `EMAIL_2FA_ENABLED=true`, la réponse est `{ "requires_2fa": true,
  "challenge_expires_in_seconds", "user" }`; aucun token n'est délivré.
* `POST /auth/login/verify-otp` — body `{ "courriel", "code" }`; consomme le
  code et retourne `access_token`, `refresh_token` et `user`.
* `POST /auth/forgot-password` — réponse volontairement non révélatrice;
  `POST /auth/verify-reset-code` vérifie sans consommer, puis
  `POST /auth/reset-password` consomme le code et change le mot de passe.

Les OTP sont hachés en base, expirent, sont limités en tentatives et ne sont
utilisables qu'une seule fois.

### Transport email et honnêteté de la réponse

L'envoi est **awaited** (pas de `BackgroundTasks`) : c'est la seule façon pour
l'API de distinguer « email accepté par le transport » de « échec ». Une tâche
de fond qui échoue en silence produit un message de succès mensonger.

| Situation | Réponse |
|---|---|
| Compte existant, livraison réussie | `200` + `expires_in_minutes` |
| Compte **inexistant** | `200` + message générique (anti-énumération préservé) |
| Livraison échouée (transport, quota, config) | `503` + `Retry-After: 60` |

L'anti-énumération reste intacte pour le cas « compte inexistant », mais un `503`
implique nécessairement qu'un compte existe : c'est le compromis assumé pour
supprimer le faux « Code envoyé ». Même règle sur le challenge 2FA de
`/auth/login` et `/auth/google` : si l'OTP ne part pas, la réponse est `503` et
aucun challenge n'est annoncé.

Transport (`EMAIL_PROVIDER` = `brevo` | `smtp` | `auto`) :

* **Brevo** (recommandé) — API REST en HTTPS/443. Render et la plupart des
  hébergeurs cloud bloquent les ports SMTP sortants, ce qui rend le SMTP
  inutilisable en production. 300 emails/jour en formule gratuite.
* **SMTP** — conservé pour le développement local. `EMAIL_PROVIDER=auto` choisit
  Brevo dès que `BREVO_API_KEY` est défini, sinon SMTP.

Seules les erreurs **transitoires** sont réessayées (3 tentatives, backoff
exponentiel) : un 4xx, une clé absente ou un mot de passe SMTP invalide échoue
immédiatement. `GET /health` expose `integrations.email` (provider, configured,
from) pour diagnostiquer sans lire les logs de déploiement.

## PostgreSQL Neon et déploiement Render

Le développement local continue d'utiliser PostgreSQL Docker. Pour Render,
configurer les variables suivantes dans l'environnement du service :

```env
DATABASE_URL=postgresql+asyncpg://...-pooler.../interviewprep?ssl=require
DATABASE_DIRECT_URL=postgresql://.../interviewprep?sslmode=require
DATABASE_POOL_SIZE=5
DATABASE_MAX_OVERFLOW=5
```

`DATABASE_URL` doit être l'URL pooled Neon pour les requêtes de l'API.
`DATABASE_DIRECT_URL` doit être l'URL directe Neon et ne sert qu'aux
migrations Alembic. Ne pas ajouter ces URLs ou leurs mots de passe au dépôt.

Configuration Render recommandée :

```text
Build command: pip install -r requirements.txt
Start command: uvicorn app.main:app --host 0.0.0.0 --port $PORT
Migration command: alembic upgrade head
Health check path: /health
```

Créer d'abord la base Neon, renseigner les variables Render, exécuter
`alembic upgrade head`, puis vérifier `/health` et `/docs`. Cette procédure
crée le schéma depuis les migrations; elle ne transfère pas les données de
l'ancienne base Railway.

## Diagnostic : `GET /health`

Au-delà de `status` et `version`, l'endpoint expose la configuration **résolue**
des intégrations externes — jamais aucun secret :

```json
{
  "status": "ok",
  "integrations": {
    "email":  { "provider": "brevo", "configured": true, "from": "..." },
    "ai":     { "provider": "groq", "base_url": "...", "configured": true,
                "fallback_provider": false },
    "storage":{ "provider": "cloudinary", "configured": true },
    "google_sign_in": true
  }
}
```

C'est le premier réflexe lorsqu'un « Code envoyé » n'arrive pas, qu'une
génération échoue en 503 ou qu'un avatar renvoie une erreur : `configured:
false` distingue une clé absente d'un service injoignable, ce que les logs de
requête ne permettent pas.

## Clé d'application Flutter

Le backend accepte une clé commune Android/iOS dans `X-API-Key`. En production,
définir `BACKEND_API_KEY` dans Render et utiliser la même valeur au build Flutter :

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.onrender.com --dart-define=BACKEND_API_KEY=...
flutter build ios --release --dart-define=API_BASE_URL=https://your-api.onrender.com --dart-define=BACKEND_API_KEY=...
```

La clé est vérifiée sur les routes `/api/v1`; les routes privées exigent
toujours un JWT utilisateur. Comme elle est embarquée dans l'application, elle
doit être considérée comme un identifiant d'application et être renouvelée
avec une nouvelle version Android/iOS.

## Stockage Cloudinary des avatars

Pour activer Cloudinary, définir `STORAGE_PROVIDER=cloudinary` et renseigner
les variables suivantes dans l'environnement du backend :

```env
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
CLOUDINARY_FOLDER=interviewprep/avatars
MAX_UPLOAD_BYTES=5242880
```

> ⚠️ Cloudinary n'attribue que des noms de cloud **alphanumériques courts** du
> type `dab1234xy`. Un nom lisible comme `interviewprep_storage` est invalide et
> fait échouer chaque upload. La valeur se trouve dans le Dashboard Cloudinary.

Après ajout de ces variables, appliquer `alembic upgrade head`. L'endpoint
`PUT /api/v1/profile/avatar` conserve son contrat multipart : le backend
envoie l'image à Cloudinary, la redimensionne pour un avatar et utilise le
format WebP explicite (`f_webp`). L'ancien avatar est supprimé avec son
`public_id`.

Les erreurs du fournisseur ne remontent plus en 500 avec une tracebox : le
routeur les convertit en `502` + `X-Error-Code: STORAGE_UNAVAILABLE`, et un
fichier au-delà de `MAX_UPLOAD_BYTES` en `413`, **avant** tout appel réseau.

## Fournisseur IA, quota épuisé et repli

`AI_PROVIDER` est consommé par le code et sélectionne un preset d'URL de
fournisseur compatible OpenAI :

| `AI_PROVIDER` | URL | Variable de clé |
|---|---|---|
| `openai` | (défaut SDK) | `OPENAI_API_KEY` |
| `groq` | `https://api.groq.com/openai/v1` | `GROQ_API_KEY` |
| `openrouter` | `https://openrouter.ai/api/v1` | `OPENROUTER_API_KEY` |
| `together` | `https://api.together.xyz/v1` | `TOGETHER_API_KEY` |
| `cerebras` | `https://api.cerebras.ai/v1` | `CEREBRAS_API_KEY` |
| `deepseek` | `https://api.deepseek.com/v1` | `DEEPSEEK_API_KEY` |
| `sambanova` | `https://api.sambanova.ai/v1` | `SAMBANOVA_API_KEY` |
| `mistral` | `https://api.mistral.ai/v1` | `MISTRAL_API_KEY` |

`AI_BASE_URL` reste prioritaire sur le preset (endpoint personnalisé) et
`AI_API_KEY` prioritaire sur la clé du preset. `OPENAI_API_KEY` n'est donc plus
obligatoire : une bascule de fournisseur ne casse plus le chargement des
settings. Les modèles du sélecteur frontend sont lus depuis `AI_MODEL_ID_*`
comme `OPENAI_MODEL_ID_*`.

### Distinguer quota facturé et rate-limit

C'est la distinction qui manquait et qui coûtait ~7 s par requête :

* `insufficient_quota`, `credit_balance_exhausted`,
  `billing_hard_limit_reached` → **le compte n'a plus de crédits**. Aucun retry
  ne peut aboutir, sur aucun modèle, car tous partagent le même compte. Le
  client IA lève alors `QuotaExceededError`, **sans** tenter `AI_FALLBACK_MODEL`.
* tout autre `429` → vrai dépassement de débit : le retry par défaut de l'SDK
  s'applique et l'erreur remonte telle quelle.

`AI_MAX_RETRIES` vaut `0` par défaut : le retry automatique du SDK est
désactivé, sinon chaque échec de facturation déclenchait 3 appels identiques.

Après `AI_QUOTA_CIRCUIT_THRESHOLD` échecs de facturation consécutifs, un
coupe-circuit ouvert court-circuite les requêtes suivantes pendant
`AI_QUOTA_CIRCUIT_COOLDOWN_SECONDS` : elles échouent en quelques
millisecondes, sans requête réseau.

Côté API, un quota épuisé renvoie `503` + `Retry-After: 120` +
`X-Error-Code: AI_QUOTA_EXCEEDED`.

`AI_FALLBACK_BASE_URL` / `AI_FALLBACK_API_KEY` pointent vers un fournisseur
**distinct** (compte distinct) : c'est la seule repli qui survive à un compte
épuisé. Les vérifier dans `GET /health` → `integrations.ai`.
