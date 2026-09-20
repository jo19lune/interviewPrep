import os
import sys
from datetime import datetime
from uuid import UUID

import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.data.database import get_db
from app.main import app
from app.models.base import Base
from app.models.exercice import Exercice
from app.models.qa_feedback import QAFeedback
from app.models.session import Session
from app.models.user import User
from app.services.auth_service import hash_password
from app.services.ai_service import AIService
from app.services import simulation_operations


TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture
async def qa_client(monkeypatch):
    engine = create_async_engine(
        TEST_DATABASE_URL,
        poolclass=StaticPool,
        connect_args={"check_same_thread": False},
    )
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)

    session_factory = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )

    async def override_get_db():
        async with session_factory() as session:
            yield session

    async with session_factory() as session:
        user = User(
            courriel="qa@example.com",
            mot_de_passe_hash=hash_password("SecurePassword123!"),
            est_actif=True,
        )
        session.add(user)
        await session.commit()

    app.dependency_overrides[get_db] = override_get_db

    async def fake_feedback(self, reponses, contexte, sujet=None):
        return {
            "score_global": 99,
            "points_forts": [{"domaine": "Clarte", "note": "Bonne réponse", "score": 0.9}],
            "ameliorations": [{"domaine": "Exemples", "note": "Ajouter un cas", "score": 0.6}],
            "recommandations": ["Continuer"],
        }

    monkeypatch.setattr(AIService, "generate_feedback", fake_feedback)
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://testserver",
    ) as client:
        yield client, session_factory

    app.dependency_overrides.clear()
    await engine.dispose()


@pytest.mark.asyncio
async def test_qa_feedback_calculates_and_persists_score(qa_client):
    client, session_factory = qa_client
    register = await client.post(
        "/api/v1/auth/register",
        json={
            "courriel": "user@example.com",
            "mot_de_passe": "SecurePassword123!",
        },
    )
    token = register.json()["access_token"]

    response = await client.post(
        "/api/v1/qa/feedback",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "contexte": "Entretien Python",
            "reponses": [
                {
                    "text": "Parlez-moi d'un projet.",
                    "is_user": False,
                    "timestamp": "2026-09-20T00:00:00",
                },
                {
                    "text": "J'ai mené un projet avec mon équipe et obtenu 20%.",
                    "is_user": True,
                    "timestamp": "2026-09-20T00:01:00",
                },
            ],
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["score_global"] > 0
    assert body["points_forts"]
    assert body["ameliorations"]

    async with session_factory() as session:
        saved = await session.get(QAFeedback, UUID(body["id"]))
        assert saved is not None
        assert saved.score_global == body["score_global"]


@pytest.mark.asyncio
async def test_process_user_answer_does_not_expose_live_score(monkeypatch):
    engine = create_async_engine(
        TEST_DATABASE_URL,
        poolclass=StaticPool,
        connect_args={"check_same_thread": False},
    )
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)

    async def fake_generate_next_question(exercice, reponses, index, model=None):
        return "Question suivante"

    monkeypatch.setattr(simulation_operations, "generate_next_question", fake_generate_next_question)

    session_factory = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with session_factory() as db:
        user = User(
            courriel="live-score@example.com",
            mot_de_passe_hash=hash_password("SecurePassword123!"),
            est_actif=True,
        )
        exercice = Exercice(
            titre="Exercice test",
            description="Description",
            domaine="TECHNIQUE",
            difficulte="INTERMEDIAIRE",
            duree_sec=300,
            questions=[{"enonce": "Question 1"}],
            etiquettes=["test"],
        )
        db.add(user)
        await db.flush()
        db.add(exercice)
        await db.flush()
        session = Session(
            utilisateur_id=user.id,
            exercice_id=exercice.id,
            commence_le=datetime.utcnow(),
            statut="EN_COURS",
            reponses=[{"type": "system", "simulation_config": {"nombre_questions": 1}}],
        )
        db.add(session)
        await db.commit()
        await db.refresh(user)
        await db.refresh(exercice)
        await db.refresh(session)

        result = await simulation_operations.process_user_answer(db, user, session.id, "Réponse de test")

        assert result["status"] == "received"
        assert "clarity_score" not in result
        assert "sentiment" not in result
        assert "coaching_tip" not in result
        assert "analysis" not in result
        assert result["next_question"] == "Question suivante"

    await engine.dispose()
