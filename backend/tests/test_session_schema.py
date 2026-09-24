import pytest
from pydantic import ValidationError

from app.config.settings import settings
from app.schemas.session import SessionCreateRequest

UUID_VALID = "00000000-0000-0000-0000-000000000001"


def _seed_models(monkeypatch):
    # Injecte une liste stable de modèles dans model_extra (restaurée après le test).
    monkeypatch.setitem(settings.model_extra, "OPENAI_MODEL_ID_1", "gpt-4o")
    monkeypatch.setitem(settings.model_extra, "OPENAI_MODEL_ID_2", "gpt-4o-mini")


def test_valid_model_accepted(monkeypatch):
    _seed_models(monkeypatch)
    req = SessionCreateRequest(exercice_id=UUID_VALID, model="gpt-4o")
    assert req.model == "gpt-4o"


def test_unknown_model_rejected(monkeypatch):
    _seed_models(monkeypatch)
    with pytest.raises(ValidationError) as excinfo:
        SessionCreateRequest(exercice_id=UUID_VALID, model="claude-3.5-sonnet")
    assert "gpt-4o" in str(excinfo.value)
    assert "gpt-4o-mini" in str(excinfo.value)


def test_none_model_accepted(monkeypatch):
    _seed_models(monkeypatch)
    req = SessionCreateRequest(exercice_id=UUID_VALID)
    assert req.model is None