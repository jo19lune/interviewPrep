"""Configuration pytest partagée.

Neutralise l'environnement hérité du vrai `.env` AVANT l'import de
l'application : `app.config.settings` instancie `Settings()` au premier
import et lit le `.env`. Sans ce bloc, une vraie `BACKEND_API_KEY` active
le middleware `verify_backend_api_key`, qui répond 401 sur chaque appel
`/api/v1` sans header `X-API-Key` — or les tests HTTP n'en envoient pas.

Satisfait également les champs `Settings` dépourvus de valeur par défaut, pour
que la suite ne dépende d'aucun secret réel ni du contenu du `.env` local :
sans cela, un `.env` incomplet (clé OpenAI commentée lors d'une bascule de
fournisseur IA) fait échouer la collection de *tous* les tests.

Le middleware lui-même reste testé isolément dans `tests/test_app_key.py`.
"""

import os

os.environ["BACKEND_API_KEY"] = ""
os.environ["APP_ENVIRONMENT"] = "development"
os.environ.setdefault("OPENAI_API_KEY", "test-openai-key")
os.environ.setdefault("AI_PRIMARY_MODEL", "test-primary-model")
os.environ.setdefault("AI_FALLBACK_MODEL", "test-fallback-model")
