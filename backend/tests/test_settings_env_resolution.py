"""Résolution des variables d'environnement hors schéma.

Contexte : en production (Render, conteneur Docker) il n'existe aucun fichier
`.env` — la configuration passe uniquement par l'environnement du processus.
Or `pydantic-settings` ne remonte dans `model_extra` les variables non
déclarées au schéma que si elles proviennent d'un FICHIER `.env`. Sur un
modèle minimal, `extra="allow"` laisse `model_extra == {}` : l'environnement du
processus n'alimente jamais les extras.

Résultat avant correction : en local tout fonctionnait (un `.env` existe), en
production `GROQ_API_KEY` et `AI_MODEL_ID_*` étaient invisibles. Premier
symptôme : un refus de démarrer (« No API key for AI provider 'groq' »).
Second, plus discret : un sélecteur de modèles retombant sur la liste OpenAI
codée en dur, exposant `gpt-4o` à une API Groq — chaque choix aurait échoué.

Ces tests n'utilisent que des variables de fournisseur absentes du `.env` de
développement, pour ne pas dépendre de son contenu.
"""

import pytest

from app.config.settings import Settings


def _settings() -> Settings:
    """Instance neuve de `Settings`, comme au démarrage de l'application.

    Le singleton `settings` est construit à l'import : pour observer l'effet
    d'une variable modifiée en cours de test, il faut réinstancier. Les champs
    obligatoires (DATABASE_URL, SECRET_KEY, modèles IA) sont satisfaits par
    l'environnement de test ou le `.env` local.
    """
    return Settings()


def _clear_ai_keys(monkeypatch) -> None:
    """Neutralise toute clé IA, quelle que soit sa source.

    On pose une chaîne vide plutôt que de supprimer la variable : le `.env`
    local est une seconde source, non modifiable depuis un test, et
    l'environnement du processus garde la priorité. Une valeur vide est
    ignorée par les deux accesseurs de clé.
    """
    for variable in (
        "AI_API_KEY",
        "GROQ_API_KEY",
        "OPENROUTER_API_KEY",
        "TOGETHER_API_KEY",
        "CEREBRAS_API_KEY",
        "DEEPSEEK_API_KEY",
        "SAMBANOVA_API_KEY",
        "MISTRAL_API_KEY",
        "OPENAI_API_KEY",
    ):
        monkeypatch.setenv(variable, "")


@pytest.mark.parametrize(
    ("provider", "variable", "valeur"),
    [
        ("groq", "GROQ_API_KEY", "gsk_abc"),
        ("openrouter", "OPENROUTER_API_KEY", "sk-or_abc"),
        ("together", "TOGETHER_API_KEY", "sk-together_abc"),
        ("cerebras", "CEREBRAS_API_KEY", "csk-abc"),
        ("deepseek", "DEEPSEEK_API_KEY", "sk-deepseek_abc"),
        ("sambanova", "SAMBANOVA_API_KEY", "sk-sambanova_abc"),
        ("mistral", "MISTRAL_API_KEY", "sk-mistral_abc"),
    ],
)
def test_chaque_preset_de_fournisseur_resout_sa_cle(monkeypatch, provider, variable, valeur):
    """La clé du preset est lue depuis l'environnement du processus.

    Régression : sans lecture de `os.environ`, toutes ces variables se
    résolvaient vers la chaîne vide en production et l'application refusait de
    démarrer. Elles ne sont déclarées nulle part au schéma.
    """
    _clear_ai_keys(monkeypatch)
    monkeypatch.setenv("AI_PROVIDER", provider)
    monkeypatch.setenv(variable, valeur)

    settings = _settings()

    assert settings.resolved_ai_provider == provider
    assert settings.resolved_ai_api_key == valeur
    assert settings.resolved_ai_base_url, "un preset doit fournir son URL de base"


def test_environnement_prime_sur_fichier_env(monkeypatch):
    """Priorité pydantic habituelle : le processus gagne sur le fichier `.env`."""
    _clear_ai_keys(monkeypatch)
    monkeypatch.setenv("AI_PROVIDER", "openrouter")
    monkeypatch.setenv("OPENROUTER_API_KEY", "depuis-processus")

    assert _settings().resolved_ai_api_key == "depuis-processus"


def test_ordre_de_priorite_des_cles(monkeypatch):
    """AI_API_KEY, puis la clé du preset, puis OPENAI_API_KEY."""
    _clear_ai_keys(monkeypatch)
    monkeypatch.setenv("AI_PROVIDER", "groq")
    monkeypatch.setenv("GROQ_API_KEY", "du-preset")
    monkeypatch.setenv("OPENAI_API_KEY", "openai")

    monkeypatch.setenv("AI_API_KEY", "generique")
    assert _settings().resolved_ai_api_key == "generique"

    monkeypatch.delenv("AI_API_KEY")
    assert _settings().resolved_ai_api_key == "du-preset"


def test_liste_de_modeles_lue_depuis_l_environnement(monkeypatch):
    """`AI_MODEL_ID_*` alimente le sélecteur en production.

    Régression : sans cela, `openai_models` retombait sur sa liste OpenAI codée
    en dur et proposait `gpt-4o` à une API Groq.
    """
    monkeypatch.setenv("AI_MODEL_ID_1", "modele-de-test-a")
    monkeypatch.setenv("AI_MODEL_ID_2", "modele-de-test-b")

    models = _settings().openai_models

    assert "modele-de-test-a" in models
    assert "modele-de-test-b" in models


def test_extra_env_expose_les_variables_non_declarees(monkeypatch):
    """Le mécanisme-même, isolé des consommateurs."""
    _clear_ai_keys(monkeypatch)
    monkeypatch.setenv("UNE_VARIABLE_HORS_SCHEMA", "valeur")

    assert _settings().extra_env["UNE_VARIABLE_HORS_SCHEMA"] == "valeur"


def test_demarrage_accepte_une_cle_venue_de_l_environnement(monkeypatch):
    """Le garde-fou de démarrage ne doit pas refuser une clé pourtant présente."""
    from app.core import app_key

    _clear_ai_keys(monkeypatch)
    monkeypatch.setenv("AI_PROVIDER", "groq")
    monkeypatch.setenv("GROQ_API_KEY", "gsk-valide-pour-le-demarrage")
    monkeypatch.setenv("APP_ENVIRONMENT", "production")
    monkeypatch.setattr(app_key, "settings", _settings())

    app_key.validate_ai_configuration()  # ne doit pas lever


def test_demarrage_refuse_une_cle_absente_avec_un_message_actionnable(monkeypatch):
    """Sans aucune clé, l'erreur nomme le fournisseur et la variable à poser.

    `validate_ai_configuration` ne lève qu'en production/staging ; en
    développement il se contente d'un avertissement.
    """
    from app.core import app_key

    _clear_ai_keys(monkeypatch)
    monkeypatch.setenv("AI_PROVIDER", "groq")
    monkeypatch.setenv("APP_ENVIRONMENT", "production")
    monkeypatch.setattr(app_key, "settings", _settings())

    with pytest.raises(RuntimeError) as excinfo:
        app_key.validate_ai_configuration()

    message = str(excinfo.value)
    assert "groq" in message
    assert "GROQ_API_KEY" in message


def test_en_developpement_une_cle_absente_ne_fait_pas_echouer(monkeypatch):
    """Comportement conservé : hors production, l'absence de clé n'est qu'un log."""
    from app.core import app_key

    _clear_ai_keys(monkeypatch)
    monkeypatch.setenv("AI_PROVIDER", "groq")
    monkeypatch.setenv("APP_ENVIRONMENT", "development")
    monkeypatch.setattr(app_key, "settings", _settings())

    app_key.validate_ai_configuration()  # ne doit pas lever
