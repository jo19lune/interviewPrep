"""Tests du parsing FRONTEND_URL (URL unique, liste JSON, CSV, valeurs vides).

Régression : Settings() plantait quand FRONTEND_URL était une URL simple car
le champ était typé List[AnyHttpUrl] (pydantic-settings exigeait du JSON).
"""

from app.config.settings import Settings, parse_frontend_urls


def test_parse_url_unique():
    assert parse_frontend_urls("https://front.example.com") == ["https://front.example.com"]


def test_parse_liste_json():
    value = '["https://a.example.com", "https://b.example.com"]'
    assert parse_frontend_urls(value) == ["https://a.example.com", "https://b.example.com"]


def test_parse_liste_csv():
    value = "https://a.example.com, https://b.example.com"
    assert parse_frontend_urls(value) == ["https://a.example.com", "https://b.example.com"]


def test_parse_vide_retourne_localhost():
    assert parse_frontend_urls("") == ["http://localhost:3000"]
    assert parse_frontend_urls(None) == ["http://localhost:3000"]


def test_validator_normalise_url():
    assert Settings._normalize_frontend_url(" https://a.example.com ") == "https://a.example.com"


def test_validator_vide_retourne_localhost():
    assert Settings._normalize_frontend_url("") == "http://localhost:3000"
    assert Settings._normalize_frontend_url(None) == "http://localhost:3000"


def test_validator_accepte_liste():
    urls = ["https://a.example.com", "https://b.example.com"]
    assert Settings._normalize_frontend_url(urls) == (
        "https://a.example.com, https://b.example.com"
    )