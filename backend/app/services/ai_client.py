"""Client IA, cache et regroupement des requêtes concurrentes."""

import asyncio
import logging
import time
from hashlib import sha256

from openai import APIStatusError, AsyncOpenAI, RateLimitError

logger = logging.getLogger(__name__)


class QuotaExceededError(Exception):
    """Le fournisseur IA a refusé la requête pour dépassement de quota."""


class AIClientMixin:
    _cache = {}
    _cache_ttl = 3600
    _locks = {}

    def _init_clients(self):
        if self.settings.openai_api_key:
            self.client = AsyncOpenAI(api_key=self.settings.openai_api_key)

    async def _complete(self, prompt, model):
        if not self.client:
            raise RuntimeError("No AI client configured")
        key = sha256(f"{prompt}:{model}".encode("utf-8")).hexdigest()
        cached = self._cache.get(key)
        if cached and time.time() - cached[0] < self._cache_ttl:
            return cached[1]
        event = self._locks.get(key)
        owner = event is None
        if owner:
            event = self._locks[key] = asyncio.Event()
        else:
            await event.wait()
            cached = self._cache.get(key)
            if cached:
                return cached[1]
            return await self._complete(prompt, model)
        try:
            try:
                response = await self.client.chat.completions.create(
                    model=model,
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0.7,
                )
                result = response.choices[0].message.content or ""
                self._cache[key] = (time.time(), result)
                return result
            except RateLimitError as exc:
                raise QuotaExceededError(f"Quota exceeded for model {model}: {exc}") from exc
            except APIStatusError as exc:
                if exc.status_code == 429:
                    raise QuotaExceededError(f"Quota exceeded for model {model}: {exc}") from exc
                raise
        finally:
            self._locks.pop(key, None)
            event.set()
