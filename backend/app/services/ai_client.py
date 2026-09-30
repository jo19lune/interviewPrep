"""Client IA, cache, regroupement des requêtes concurrentes et coupe-circuit quota.

Deux distinctions gouvernent ce module :

1. **Quota facturé ≠ débit limité.** Un ``429 insufficient_quota`` /
   ``credit_balance_exhausted`` signifie « le compte n'a plus de crédits » :
   aucun nouvel essai, ni sur le même modèle ni sur le modèle de secours, ne
   peut aboutir. Seul un vrai ``429`` de débit (``rate_limit_exceeded``)
   mérite un retry.
2. **Le coupe-circuit évite de payer le timeout à chaque requête.** Après
   ``ai_quota_circuit_threshold`` échecs consécutifs de facturation, les
   requêtes suivantes lèvent ``QuotaExceededError`` immédiatement, sans
   requête réseau, pendant ``ai_quota_circuit_cooldown_seconds``.
"""

import asyncio
import logging
import time
from hashlib import sha256

from openai import APIStatusError, AsyncOpenAI, RateLimitError

logger = logging.getLogger(__name__)

# Codes renvoyés par OpenAI quand l'échec est un problème de facturation et non
# un dépassement de débit. Tout est dans le même compte : re-tenter avec un autre
# modèle du même compte échouerait identiquement.
_QUOTA_BILLING_CODES = frozenset(
    {"insufficient_quota", "credit_balance_exhausted", "billing_hard_limit_reached"}
)


class QuotaExceededError(Exception):
    """Le fournisseur IA a refusé la requête pour dépassement de quota."""


class _QuotaCircuit:
    """Coupe-circuit partagé par tous les clients IA du process."""

    def __init__(self) -> None:
        self.failures = 0
        self.opened_at = 0.0

    def is_open(self, threshold: int, cooldown: int) -> bool:
        if self.failures < threshold:
            return False
        return (time.monotonic() - self.opened_at) < cooldown

    def record_failure(self, threshold: int) -> None:
        self.failures += 1
        if self.failures == threshold:
            self.opened_at = time.monotonic()
            logger.warning(
                "AI quota circuit opened after %d consecutive quota failures",
                threshold,
            )

    def record_success(self) -> None:
        self.failures = 0

    def reset(self) -> None:
        self.failures = 0
        self.opened_at = 0.0


_quota_circuit = _QuotaCircuit()


def is_quota_billing_error(exc: Exception) -> bool:
    """Vrai si l'erreur OpenAI traduit un manque de crédits, pas un débit."""
    code = getattr(exc, "code", None)
    if isinstance(code, str) and code in _QUOTA_BILLING_CODES:
        return True
    body = getattr(exc, "body", None)
    if isinstance(body, dict):
        error = body.get("error")
        if isinstance(error, dict):
            for key in ("code", "type"):
                value = error.get(key)
                if isinstance(value, str) and value in _QUOTA_BILLING_CODES:
                    return True
    return False


class AIClientMixin:
    _cache = {}
    _cache_ttl = 3600
    _locks = {}

    def _build_client(self, api_key: str, base_url: str | None) -> AsyncOpenAI | None:
        if not api_key:
            return None
        kwargs = {
            "api_key": api_key,
            # Le retry par défaut de l'SDK (2) transforme une erreur de
            # facturation en 3 appels inutiles de plusieurs secondes.
            "max_retries": self.settings.ai_max_retries,
        }
        if base_url:
            kwargs["base_url"] = base_url
        return AsyncOpenAI(**kwargs)

    def _init_clients(self):
        # `resolved_ai_base_url` / `resolved_ai_api_key` rendent le fournisseur
        # pilotable par l'environnement : n'importe quel fournisseur compatible
        # OpenAI (Groq, OpenRouter, Together…) fonctionne sans changer le code.
        self.client = self._build_client(
            self.settings.resolved_ai_api_key,
            self.settings.resolved_ai_base_url or None,
        )
        self.fallback_client = (
            self._build_client(
                self.settings.ai_fallback_api_key,
                self.settings.ai_fallback_base_url,
            )
            if self.settings.ai_has_fallback_provider
            else None
        )

    def _client_for_model(self, model: str):
        """Client à utiliser : le secours si l'on tente explicitement le modèle de repli."""
        if model == self.fallback_model and self.fallback_client is not None:
            return self.fallback_client
        return self.client

    async def _complete(self, prompt, model, client=None):
        if not self.client:
            raise RuntimeError("No AI client configured")
        active_client = client or self._client_for_model(model)
        if active_client is None:
            active_client = self.client

        threshold = self.settings.ai_quota_circuit_threshold
        cooldown = self.settings.ai_quota_circuit_cooldown_seconds
        if _quota_circuit.is_open(threshold, cooldown):
            remaining = cooldown - int(time.monotonic() - _quota_circuit.opened_at)
            raise QuotaExceededError(
                f"AI quota circuit is open for model {model}; "
                f"retry in ~{remaining}s without calling the provider"
            )

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
            return await self._complete(prompt, model, client)
        try:
            try:
                response = await active_client.chat.completions.create(
                    model=model,
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0.7,
                )
                result = response.choices[0].message.content or ""
                self._cache[key] = (time.time(), result)
                _quota_circuit.record_success()
                return result
            except RateLimitError as exc:
                if is_quota_billing_error(exc):
                    _quota_circuit.record_failure(threshold)
                    raise QuotaExceededError(
                        f"Quota exceeded for model {model}: {exc}"
                    ) from exc
                # Vrai dépassement de débit : le retry par défaut de l'SDK a
                # déjà eu lieu, on remonte tel quel.
                raise
            except APIStatusError as exc:
                if exc.status_code == 429 and is_quota_billing_error(exc):
                    _quota_circuit.record_failure(threshold)
                    raise QuotaExceededError(
                        f"Quota exceeded for model {model}: {exc}"
                    ) from exc
                raise
        finally:
            self._locks.pop(key, None)
            event.set()
