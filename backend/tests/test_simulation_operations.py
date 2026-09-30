"""Idempotence et codes d'erreur des opérations de simulation.

Régression : le log de production montre `finish` 200 → `cancel` 400 → `finish`
200 **sur la même session**. Les 400 n'étaient pas des requêtes malformées mais
des endpoints non idempotents : le client ne pouvait rien en faire, et
l'utilisateur voyait une erreur après une action qui avait pourtant réussi.

Règles vérifiées ici :
* `cancel` / `finish` rejoués sont des succès (HTTP 200), pas des erreurs.
* `answer` sur une session close renvoie 409 + `X-Error-Code`, pas 400.
* Une nouvelle session clôt les sessions `EN_COURS` orphelines.
"""

import os
import sys
from datetime import datetime, timezone
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch
from uuid import UUID, uuid4

import pytest
from fastapi import HTTPException

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("SECRET_KEY", "test-secret-key")
os.environ.setdefault("ACCESS_TOKEN_EXPIRE_MINUTES", "30")
os.environ.setdefault("REFRESH_TOKEN_EXPIRE_MINUTES", "60")
os.environ.setdefault("UPLOAD_BASE_URL", "http://localhost:8000/media")

from app.services import simulation_operations as ops

_USER_ID = UUID("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")
_EXERCICE_ID = uuid4()


def _user() -> SimpleNamespace:
    return SimpleNamespace(id=_USER_ID)


def _session(statut: str, *, retour=None, reponses=None) -> SimpleNamespace:
    return SimpleNamespace(
        id=uuid4(),
        utilisateur_id=_USER_ID,
        exercice_id=_EXERCICE_ID,
        statut=statut,
        termine_le=None,
        score=None,
        reponses=reponses or [],
        retour=retour,
        ia_simulation=None,
    )


def _feedback() -> SimpleNamespace:
    return SimpleNamespace(
        id=uuid4(),
        session_id=uuid4(),
        score_global=80.0,
        points_forts=["Clarté"],
        ameliorations=["Précision"],
        recommandations=["Exemples chiffrés"],
        genere_le=datetime(2026, 1, 1, tzinfo=timezone.utc),
    )


class _ScalarResult:
    def __init__(self, value):
        self._value = value

    def scalars(self):
        return self

    def first(self):
        return self._value

    def all(self):
        return self._value if isinstance(self._value, list) else [self._value]


class _FakeDb:
    """Double d'`AsyncSession` qui sert des résultats préprogrammés.

    `queue` associe chaque appel à `db.execute` au résultat correspondant, ce
    qui évite de monter une base pour tester la logique d'état.
    """

    def __init__(self, queue):
        self._queue = list(queue)
        self.commits = 0

    async def execute(self, *args, **kwargs):
        if not self._queue:
            raise AssertionError("db.execute appelé plus de fois que prévu")
        return _ScalarResult(self._queue.pop(0))

    async def commit(self):
        self.commits += 1

    async def refresh(self, obj):
        return None

    def add_all(self, objs):
        return None


# --------------------------------------------------------------------------
# cancel_active_session
# --------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_cancel_active_session_closes_running_session():
    session = _session("EN_COURS")
    db = _FakeDb([session])

    with patch.object(ops, "utc_now", lambda: datetime(2026, 1, 1, tzinfo=timezone.utc)):
        result = await ops.cancel_active_session(db, _user(), session.id)

    assert result["status"] == "cancelled"
    assert result["session_status"] == "ANNULEE"
    assert session.statut == "ANNULEE"


@pytest.mark.asyncio
async def test_cancel_is_idempotent_on_already_cancelled_session():
    """Le 400 « Only active sessions can be cancelled » observait une session
    déjà close : l'utilisateur ne pouvait que réessayer, sans effet."""
    session = _session("ANNULEE")
    db = _FakeDb([session])

    result = await ops.cancel_active_session(db, _user(), session.id)

    assert result["status"] == "already_cancelled"
    assert result["session_status"] == "ANNULEE"
    assert db.commits == 0, "aucune écriture nécessaire sur une session déjà close"


@pytest.mark.asyncio
async def test_cancel_is_idempotent_on_finished_session():
    session = _session("TERMINEE")
    db = _FakeDb([session])

    result = await ops.cancel_active_session(db, _user(), session.id)

    assert result["status"] == "already_finished"
    assert result["session_status"] == "TERMINEE"


@pytest.mark.asyncio
async def test_cancel_unknown_session_still_404():
    db = _FakeDb([None])
    with pytest.raises(HTTPException) as excinfo:
        await ops.cancel_active_session(db, _user(), uuid4())
    assert excinfo.value.status_code == 404


# --------------------------------------------------------------------------
# finish_session_and_generate_feedback
# --------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_finish_is_idempotent_and_returns_existing_feedback():
    """Le second `finish` sur une session terminée renvoie le bilan existant,
    sans rappeler l'IA (coûte) ni incrémenter la progression deux fois."""
    feedback = _feedback()
    session = _session("TERMINEE", retour=feedback, reponses=[{"texte": "a"}])
    session.score = 82.0
    db = _FakeDb([session])

    with patch.object(
        ops, "generate_feedback", AsyncMock(side_effect=AssertionError("IA ne doit pas être appelée"))
    ) as generate:
        result = await ops.finish_session_and_generate_feedback(db, _user(), session.id)

    generate.assert_not_called()
    assert result["status"] == "finished"
    assert result["feedback"]["id"] == str(feedback.id)
    assert db.commits == 0


@pytest.mark.asyncio
async def test_finish_on_cancelled_session_returns_409_with_code():
    session = _session("ANNULEE")
    db = _FakeDb([session])

    with pytest.raises(HTTPException) as excinfo:
        await ops.finish_session_and_generate_feedback(db, _user(), session.id)

    assert excinfo.value.status_code == 409
    assert excinfo.value.headers["X-Error-Code"] == "SESSION_CANCELLED"


@pytest.mark.asyncio
async def test_finish_unknown_session_still_404():
    db = _FakeDb([None])
    with pytest.raises(HTTPException) as excinfo:
        await ops.finish_session_and_generate_feedback(db, _user(), uuid4())
    assert excinfo.value.status_code == 404


# --------------------------------------------------------------------------
# process_user_answer
# --------------------------------------------------------------------------


@pytest.mark.asyncio
@pytest.mark.parametrize("statut", ["TERMINEE", "ANNULEE"])
async def test_answer_on_closed_session_returns_409_not_400(statut):
    """409 + `X-Error-Code` : le client Flutter distingue « session morte » d'une
    erreur de validation, ce qu'un 400 ne permettait pas."""
    session = _session(statut)
    db = _FakeDb([session])

    with pytest.raises(HTTPException) as excinfo:
        await ops.process_user_answer(db, _user(), session.id, "ma reponse")

    assert excinfo.value.status_code == 409
    assert excinfo.value.headers["X-Error-Code"] == ops.SESSION_NOT_ACTIVE_CODE
    assert statut.lower() in excinfo.value.detail


@pytest.mark.asyncio
async def test_answer_empty_stays_422():
    """Une réponse vide reste une erreur de validation, pas un conflit d'état."""
    with pytest.raises(HTTPException) as excinfo:
        await ops.process_user_answer(_FakeDb([]), _user(), uuid4(), "   ")
    assert excinfo.value.status_code == 422


# --------------------------------------------------------------------------
# create_simulation_session : purge des sessions orphelines
# --------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_creating_a_session_closes_stale_running_sessions():
    """Sans cette purge, une session abandonnée reste `EN_COURS` : c'est
    l'origine des 400 en rafale, l'app considérant la session encore active.

    Le test s'arrête volontairement sur l'exercice introuvable : la purge est
    déjà écrite et validée à ce stade, et cela évite de devoir construire de
    vrais modèles SQLAlchemy.
    """
    stale = [_session("EN_COURS"), _session("EN_COURS")]
    # 1) select des sessions EN_COURS, 2) select de l'exercice → absent.
    db = _FakeDb([stale, None])
    request = SimpleNamespace(
        exercice_id=_EXERCICE_ID, subject=None, question_count=3, model=None,
    )

    with patch.object(
        ops, "utc_now", lambda: datetime(2026, 1, 1, tzinfo=timezone.utc)
    ):
        with pytest.raises(HTTPException) as excinfo:
            await ops.create_simulation_session(db, _user(), request)

    assert excinfo.value.status_code == 404
    assert all(s.statut == "ANNULEE" for s in stale), "les sessions orphelines doivent être closes"
    assert all(s.termine_le is not None for s in stale)
    assert db.commits == 1, "la purge doit être persistée"


@pytest.mark.asyncio
async def test_creating_a_session_does_not_commit_when_no_stale_session():
    """Pas de commit inutile quand rien n'a été clôturé."""
    db = _FakeDb([[], None])
    request = SimpleNamespace(
        exercice_id=_EXERCICE_ID, subject=None, question_count=3, model=None,
    )

    with pytest.raises(HTTPException):
        await ops.create_simulation_session(db, _user(), request)

    assert db.commits == 0