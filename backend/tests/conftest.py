"""Configuration pytest partagée.

Neutralise l'environnement hérité du vrai `.env` AVANT l'import de
l'application : `app.config.settings` instancie `Settings()` au premier
import et lit le `.env`. Sans ce bloc, une vraie `BACKEND_API_KEY` active
le middleware `verify_backend_api_key`, qui répond 401 sur chaque appel
`/api/v1` sans header `X-API-Key` — or les tests HTTP n'en envoient pas.

Le middleware lui-même reste testé isolément dans `tests/test_app_key.py`.
"""

import os

os.environ["BACKEND_API_KEY"] = ""
os.environ["APP_ENVIRONMENT"] = "development"