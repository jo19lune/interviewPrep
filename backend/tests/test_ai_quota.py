"""Comportement du client IA face à un quota épuisé.

Le défaut observé en production : chaque requête payait ~7 s et 6 appels
HTTP (3 par modèle) avant d'échouer, la erreur de facturation étant traitée
comme un rate-limit ordinaire — puis `_with_fallback` réessayait avec un
second modèle du **même compte**, ce qui ne pouvait pas aboutir.
"""

import httpx
import pytest
from openai import RateLimitError
from pydantic import ValidationError

from app.services import ai_client as ai_client_module
from app.services.ai_client import (
    AIClientMixin,
    QuotaExceededError,
    is_quota_billing_error,
)
from app.services.ai_service import AIService

QUOTA_BODY = {
    "error": {
        "message": "You have no credits remaining.",
        "type": "insufficient_quota",
        "code": "credit_balance_exhausted",
    }
}


def _quota_error() -> RateLimitError:
    request = httpx.Request("POST", "https://api.openai.com/v1/chat/completions")
    response = httpx.Response(429, json=QUOTA_BODY, request=request)
    error = RateLimitError("quota", response=response, body=QUOTA_BODY)
    return error


def _rate_limit_error() -> RateLimitError:
    body = {"error": {"message": "Rate limit reached", "type": "rate_limit_error"}}
    request = httpx.Request("POST", "https://api.openai.com/v1/chat/completions")
    response = httpx.Response(429, json=body, request=request)
    return RateLimitError("rate limited", response=response, body=body)


class _FakeSettings:
    """Doublure minimale de Settings pour piloter le client sans .env."""

    def __init__(self, **overrides):
        self.openai_api_key = "sk-test"
        self.ai_api_key = ""
        self.ai_provider = "openai"
        self.ai_base_url = ""
        self.resolved_ai_base_url = ""
        self.resolved_ai_api_key = "sk-test"
        self.ai_fallback_base_url = ""
        self.ai_fallback_api_key = ""
        self.ai_has_fallback_provider = False
        self.ai_max_retries = 0
        self.ai_primary_model = "gpt-4o"
        self.ai_fallback_model = "gpt-4o-mini"
        self.ai_quota_circuit_threshold = 3
        self.ai_quota_circuit_cooldown_seconds = 120
        self.openai_models = ["gpt-4o", "gpt-4o-mini"]
        for key, value in overrides.items():
            setattr(self, key, value)


@pytest.fixture(autouse=True)
def reset_state():
    """Le coupe-circuit est un état de module : il doit être isolé par test."""
    ai_client_module._quota_circuit.reset()
    AIClientMixin._cache = {}
    AIClientMixin._locks = {}
    yield
    ai_client_module._quota_circuit.reset()


def test_is_quota_billing_error_distinguishes_billing_from_throttling():
    assert is_quota_billing_error(_quota_error()) is True
    assert is_quota_billing_error(_rate_limit_error()) is False


# Champs `Settings` obligatoires sans rapport avec l'IA : fournis en dur pour
# que `_env_file=None` n'aboutisse pas à un échec de validation sans rapport.
_BASE_SETTINGS = {
    "DATABASE_URL": "postgresql://user:pass@localhost:5432/test",
    "SECRET_KEY": "test-secret-key",
    "ACCESS_TOKEN_EXPIRE_MINUTES": 60,
    "REFRESH_TOKEN_EXPIRE_MINUTES": 43200,
}


def _settings(**overrides):
    """Construit un `Settings` isolé du `.env` local.

    `_env_file=None` est indispensable : sans lui, le `.env` du poste de
    développement (`AI_PROVIDER=groq`, clés commentées) s'injecte et les
    assertions ne testent plus le cas d'intérêt.
    """
    from app.config.settings import Settings

    return Settings(_env_file=None, **{**_BASE_SETTINGS, **overrides})


def test_resolved_provider_presets_are_wired():
    """AI_PROVIDER était déclaré mais jamais lu : le client partait sur OpenAI."""
    groq = _settings(
        AI_PROVIDER="groq",
        GROQ_API_KEY="gsk-test",
        AI_PRIMARY_MODEL="llama-3.3-70b-versatile",
        AI_FALLBACK_MODEL="llama-3.1-8b-instant",
    )
    assert groq.resolved_ai_provider == "groq"
    assert groq.resolved_ai_base_url == "https://api.groq.com/openai/v1"
    assert groq.resolved_ai_api_key == "gsk-test"

    # AI_BASE_URL reste prioritaire pour un endpoint personnalisé.
    custom = _settings(
        AI_PROVIDER="groq",
        AI_BASE_URL="https://proxy.interne/v1",
        AI_API_KEY="sk-proxy",
        AI_PRIMARY_MODEL="m",
        AI_FALLBACK_MODEL="m2",
    )
    assert custom.resolved_ai_base_url == "https://proxy.interne/v1"
    assert custom.resolved_ai_api_key == "sk-proxy"

    # Repli sur OPENAI_API_KEY quand le fournisseur est openai.
    openai = _settings(
        OPENAI_API_KEY="sk-openai",
        AI_PRIMARY_MODEL="gpt-4o",
        AI_FALLBACK_MODEL="gpt-4o-mini",
    )
    assert openai.resolved_ai_base_url == ""
    assert openai.resolved_ai_api_key == "sk-openai"


def test_openai_api_key_is_optional_but_models_are_still_required(monkeypatch):
    """Une bascule vers Groq ne doit pas exiger OPENAI_API_KEY.

    Le champ était obligatoire : un `.env` préparant une bascule de fournisseur
    faisait échouer le chargement de `Settings()` — donc toute l'application.
    """
    # `conftest` en injecte une pour les autres tests ; on la retire pour
    # vérifier que le champ a bien une valeur par défaut.
    monkeypatch.delenv("OPENAI_API_KEY", raising=False)
    monkeypatch.delenv("AI_PRIMARY_MODEL", raising=False)
    monkeypatch.delenv("AI_FALLBACK_MODEL", raising=False)

    groq = _settings(
        AI_PROVIDER="groq",
        GROQ_API_KEY="gsk-test",
        AI_PRIMARY_MODEL="llama-3.3-70b-versatile",
        AI_FALLBACK_MODEL="llama-3.1-8b-instant",
        AI_MODEL_ID_1="llama-3.3-70b-versatile",
        AI_MODEL_ID_2="llama-3.1-8b-instant",
    )
    assert groq.openai_api_key == ""
    assert groq.resolved_ai_api_key == "gsk-test"
    # AI_MODEL_ID_* n'était pas lu : le frontend exposait gpt-4o à une config Groq.
    assert groq.openai_models == ["llama-3.3-70b-versatile", "llama-3.1-8b-instant"]

    # En revanche un fournisseur sans aucune clé doit rester détectable.
    without_key = _settings(AI_PRIMARY_MODEL="m", AI_FALLBACK_MODEL="m2")
    assert without_key.resolved_ai_api_key == ""

    # Les modèles restent obligatoires : sans eux, le frontend n'a rien à proposer.
    with pytest.raises(ValidationError):
        _settings(OPENAI_API_KEY="sk-x")


def test_build_client_disables_sdk_retries_on_quota():
    """max_retries=0 : un quota épuisé ne justifie pas 3 appels identiques."""
    service = AIService(settings=_FakeSettings())
    assert service.client.max_retries == 0


@pytest.mark.asyncio
async def test_quota_error_raises_quota_exceeded_without_retry(monkeypatch):
    service = AIService(settings=_FakeSettings())

    calls = []

    async def create(**kwargs):
        calls.append(kwargs)
        raise _quota_error()

    monkeypatch.setattr(
        service.client.chat.completions, "create", create, raising=False
    )

    with pytest.raises(QuotaExceededError) as excinfo:
        await service.generate_next_question([], "TECHNIQUE", "FACILE")

    assert len(calls) == 1, "un quota facturé ne doit pas être réessayé"
    assert "Quota exceeded" in str(excinfo.value)


@pytest.mark.asyncio
async def test_fallback_model_is_not_tried_on_quota_error(monkeypatch):
    """Même compte, mêmes crédits : réessayer avec gpt-4o-mini est vain."""
    service = AIService(settings=_FakeSettings())
    used_models = []

    async def create(**kwargs):
        used_models.append(kwargs["model"])
        raise _quota_error()

    monkeypatch.setattr(
        service.client.chat.completions, "create", create, raising=False
    )

    with pytest.raises(QuotaExceededError):
        await service.generate_feedback([], "contexte")

    assert used_models == ["gpt-4o"]


@pytest.mark.asyncio
async def test_rate_limit_error_is_not_treated_as_billing_quota(monkeypatch):
    """Un 429 de débit ne doit pas armer le coupe-circuit de facturation."""
    service = AIService(settings=_FakeSettings(ai_quota_circuit_threshold=1))

    async def create(**kwargs):
        raise _rate_limit_error()

    monkeypatch.setattr(
        service.client.chat.completions, "create", create, raising=False
    )

    with pytest.raises(RateLimitError):
        await service.generate_next_question([], "TECHNIQUE", "FACILE")

    assert ai_client_module._quota_circuit.failures == 0


@pytest.mark.asyncio
async def test_circuit_opens_after_threshold_and_short_circuits(monkeypatch):
    """Une fois ouvert, plus aucune requête réseau n'est émise."""
    threshold = 2
    service = AIService(settings=_FakeSettings(ai_quota_circuit_threshold=threshold))

    network_calls = []

    async def create(**kwargs):
        network_calls.append(kwargs)
        raise _quota_error()

    monkeypatch.setattr(
        service.client.chat.completions, "create", create, raising=False
    )

    for _ in range(threshold):
        with pytest.raises(QuotaExceededError):
            await service.generate_next_question([], "TECHNIQUE", "FACILE")

    assert len(network_calls) == threshold
    assert ai_client_module._quota_circuit.is_open(threshold, 120) is True

    # Les prompts suivants ne doivent plus atteindre le fournisseur.
    with pytest.raises(QuotaExceededError) as excinfo:
        await service.generate_next_question([], "TECHNIQUE", "FACILE", "sujet-unique")

    assert len(network_calls) == threshold, "le coupe-circuit doit court-circuiter"
    assert "circuit is open" in str(excinfo.value)


@pytest.mark.asyncio
async def test_circuit_closes_after_successful_call(monkeypatch):
    service = AIService(settings=_FakeSettings(ai_quota_circuit_threshold=2))

    async def failing(**kwargs):
        raise _quota_error()

    async def succeeding(**kwargs):
        class _Message:
            content = "reponse"

        class _Choice:
            message = _Message()

        class _Response:
            choices = [_Choice()]

        return _Response()

    monkeypatch.setattr(
        service.client.chat.completions, "create", failing, raising=False
    )
    with pytest.raises(QuotaExceededError):
        await service.generate_next_question([], "T", "F")
    assert ai_client_module._quota_circuit.failures == 1

    monkeypatch.setattr(
        service.client.chat.completions, "create", succeeding, raising=False
    )
    await service.generate_next_question([], "T", "F", "prompt-reussi")
    assert ai_client_module._quota_circuit.failures == 0
