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

### Transport SMTP

Transport unique : soumission authentifiée sur le port **587 + STARTTLS**.

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=votre-adresse-gmail
SMTP_PASSWORD=<mot de passe d'application Gmail>
EMAIL_USE_TLS=True
EMAIL_USE_SSL=False
EMAIL_TIMEOUT_SECONDS=8
DEFAULT_FROM_EMAIL=votre-adresse-gmail
```

**Ports.** Le 25 est bloqué par tous les hébergeurs cloud. Les ports 465 et 587
sont également bloqués sur le **free tier** de Render — ce service est en plan
`starter`, où ils sont ouverts. C'est ce qui rend le SMTP utilisable ici en
production, et non un contournement.

**Gmail impose un mot de passe d'application.** Le mot de passe du compte est
rejeté par `smtp.gmail.com` depuis 2022 ; il faut un mot de passe d'application
à 16 caractères (Compte Google → Sécurité → Validation en 2 étapes → Mots de
passe d'application). Un mot de passe de compte produit un **535**, classé
définitif : aucun retry, et l'utilisateur reçoit un `503` explicite plutôt qu'un
faux « Code envoyé ». `DEFAULT_FROM_EMAIL` doit correspondre au compte authentifié.

Plafond Google : ~500 messages/jour. Un quota dépassé renvoie un 4xx, également
classé définitif — c'est le comportement voulu, un retry n'y changerait rien.

Seules les erreurs **transitoires** sont réessayées (3 tentatives, backoff
exponentiel) : `421`, `450`, `451`, et les erreurs de connexion ou de timeout.
Un `535`/`534` (authentification) ou un autre 5xx échoue immédiatement.
`GET /health` expose `integrations.email` (`configured`, `host`, `port`, `from`)
pour diagnostiquer sans lire les logs de déploiement.

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
    "email":  { "configured": true, "host": "smtp.gmail.com", "port": 587,
                "from": "..." },
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
requête ne permettent pas. Pour l'email, `host` et `port` permettent de voir
immédiatement que l'envoi part vers le mauvais serveur.

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
comme `OPENAI_MODEL_ID_*` — **les deux préfixes sont fusionnés, pas
remplacés** : n'en définir qu'un seul, sinon le sélecteur exposerait `gpt-4o` à
une API Groq et chaque choix échouerait.

`AI_PRIMARY_MODEL` est envoyé tel quel à l'API : il doit appartenir au
catalogue de `AI_PROVIDER`. `GET /health` → `integrations.ai.primary_model`
permet de vérifier la cohérence d'un coup d'œil.

### Ces variables ne sont pas déclarées au schéma

Les clés de fournisseur et les `AI_MODEL_ID_*` ne sont **pas** des champs de
`Settings` : elles sont lues dans `os.environ` (avec repli sur un éventuel
`.env`, l'environnement du processus restant prioritaire).

Le détail compte, car il a coûté un déploiement : avec
`SettingsConfigDict(extra="allow")`, pydantic ne remonte dans `model_extra`
les variables inconnues que si elles viennent d'un **fichier** `.env`.
L'environnement du processus, lui, n'alimente jamais les extras — vérifié sur
un modèle minimal, `model_extra == {}`. En local tout fonctionnait puisqu'un
`.env` existe ; en production (Render, conteneur Docker) il n'y a aucun
`.env` et ces variables étaient **invisibles** : l'application refusait de
démarrer sur « No API key for AI provider 'groq' », et le sélecteur de
modèles retombait silencieusement sur sa liste OpenAI codée en dur.

Conséquence pour toute variable ajoutée à l'avenir : si elle n'est pas
déclarée au schéma, elle ne fonctionnera pas en production tant que la
lecture via `extra_env` ne sera pas en place.

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
