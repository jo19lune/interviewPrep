"""Logique metier des simulations d'entretien."""

import re
from datetime import datetime
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload

from app.config.settings import settings
from app.models.ai_simulation import SimulationIA
from app.models.exercice import Exercice
from app.models.feedback import Retour
from app.models.progression import Progression
from app.models.session import Session
from app.models.user import User
from app.schemas.session import SessionCreateRequest
from app.services.ai_service import AIService


async def create_simulation_session(db: AsyncSession, current_user: User, request: SessionCreateRequest):
    exercice_id = request.exercice_id
    sujet = request.subject
    nombre_questions = request.question_count
    modele = request.model

    result = await db.execute(select(Exercice).where(Exercice.id == exercice_id))
    exercice = result.scalars().first()

    if not exercice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercise not found",
        )

    session = Session(
        utilisateur_id=current_user.id,
        exercice_id=exercice_id,
        commence_le=datetime.utcnow(),
        statut="EN_COURS",
        reponses=[
            {
                "type": "system",
                "simulation_config": {
                    "sujet": sujet.strip() if sujet else None,
                    "nombre_questions": nombre_questions,
                    "domaine": exercice.domaine,
                    "difficulte": exercice.difficulte,
                },
            }
        ],
    )
    ia_sim = SimulationIA(
        modele=modele or settings.ai_primary_model or "gpt-4o-mini",
        temperature=0.7,
    )
    session.ia_simulation = ia_sim

    db.add(session)
    db.add(ia_sim)
    await db.commit()
    await db.refresh(session)
    await db.refresh(ia_sim)

    first_question = await generate_next_question(exercice, session.reponses or [], 0, model=ia_sim.modele)
    
    return {
        "session_id": str(session.id),
        "status": "started",
        "exercise_title": exercice.titre,
        "first_question": first_question,
        "subject": sujet.strip() if sujet else exercice.domaine,
        "question_count": nombre_questions,
    }

async def process_user_answer(db: AsyncSession, current_user: User, session_id: UUID, reponse: str):
    reponse = reponse.strip()
    if not reponse:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Answer cannot be empty",
        )

    result = await db.execute(
        select(Session)
        .options(selectinload(Session.ia_simulation))
        .where(
            (Session.id == session_id) & (Session.utilisateur_id == current_user.id)
        )
    )
    session = result.scalars().first()

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )
    if session.statut != "EN_COURS":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Session is not active",
        )

    ex_res = await db.execute(select(Exercice).where(Exercice.id == session.exercice_id))
    exercice = ex_res.scalars().first()
    if not exercice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercise associated with session not found",
        )

    current_q_index = len(user_responses(session.reponses or []))
    questions = exercice.questions or []
    
    if current_q_index < len(questions):
        current_question = questions[current_q_index].get("enonce")
        q_dict = questions[current_q_index]
    else:
        current_question = None
        q_dict = None
        
    clarity_score, sentiment, coaching_tip, analysis = score_answer(q_dict, reponse)

    updated_reponses = list(session.reponses or [])
    updated_reponses.append(
        {
            "texte": reponse,
            "question": current_question,
            "timestamp": datetime.utcnow().isoformat(),
            "index": current_q_index,
            "score_partiel": clarity_score,
            "sentiment": sentiment,
            "coaching_tip": coaching_tip,
            "analysis": analysis,
        }
    )
    session.reponses = updated_reponses

    model_name = session.ia_simulation.modele if session.ia_simulation else None
    next_question = await generate_next_question(exercice, updated_reponses, current_q_index + 1, model=model_name)

    db.add(session)
    await db.commit()
    await db.refresh(session)

    return {
        "status": "received",
        "answer_count": len(session.reponses or []),
        "clarity_score": clarity_score,
        "sentiment": sentiment,
        "coaching_tip": coaching_tip,
        "analysis": analysis,
        "next_question": next_question,
    }


async def cancel_active_session(db: AsyncSession, current_user: User, session_id: UUID):
    result = await db.execute(
        select(Session).where(
            (Session.id == session_id) & (Session.utilisateur_id == current_user.id)
        )
    )
    session = result.scalars().first()

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )
    if session.statut != "EN_COURS":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only active sessions can be cancelled",
        )

    session.statut = "ANNULEE"
    session.termine_le = datetime.utcnow()
    db.add(session)
    await db.commit()

    return {
        "session_id": str(session.id),
        "status": "cancelled",
    }


async def finish_session_and_generate_feedback(db: AsyncSession, current_user: User, session_id: UUID):
    result = await db.execute(
        select(Session)
        .options(selectinload(Session.ia_simulation))
        .where(
            (Session.id == session_id) & (Session.utilisateur_id == current_user.id)
        )
    )
    session = result.scalars().first()

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )

    session.statut = "TERMINEE"
    session.termine_le = datetime.utcnow()

    user_reponses = user_responses(session.reponses or [])
    scores = [
        r.get("score_partiel")
        for r in user_reponses
        if r.get("score_partiel") is not None
    ]
    global_score = float(sum(scores) / len(scores)) if scores else 75.0
    session.score = global_score

    ex_res = await db.execute(select(Exercice).where(Exercice.id == session.exercice_id))
    exercice = ex_res.scalars().first()
    model_name = session.ia_simulation.modele if session.ia_simulation else None
    feedback_data = await generate_feedback(exercice, session.reponses or [], global_score, model=model_name)

    existing_res = await db.execute(select(Retour).where(Retour.session_id == session.id))
    feedback = existing_res.scalars().first()
    
    if feedback:
        feedback.score_global = feedback_data["score_global"]
        feedback.points_forts = feedback_data["points_forts"]
        feedback.ameliorations = feedback_data["ameliorations"]
        feedback.recommandations = feedback_data["recommandations"]
        feedback.genere_le = datetime.utcnow()
    else:
        feedback = Retour(
            session_id=session.id,
            score_global=feedback_data["score_global"],
            points_forts=feedback_data["points_forts"],
            ameliorations=feedback_data["ameliorations"],
            recommandations=feedback_data["recommandations"],
            genere_le=datetime.utcnow(),
        )

    db.add(session)
    db.add(feedback)

    existing_prog = await db.execute(
        select(Progression).where(Progression.utilisateur_id == current_user.id)
    )
    prog = existing_prog.scalars().first()
    if prog:
        prog.total_sessions += 1
        prog.meilleur_score = max(prog.meilleur_score, global_score)
        prog.score_moyen = round(
            (prog.score_moyen * (prog.total_sessions - 1) + global_score) / prog.total_sessions, 2
        ) if prog.total_sessions > 0 else global_score
        prog.derniere_session_le = session.termine_le
    else:
        prog = Progression(
            utilisateur_id=current_user.id,
            domaine=exercice.domaine if exercice else None,
            total_sessions=1,
            score_moyen=global_score,
            meilleur_score=global_score,
            serie=0,
            derniere_session_le=session.termine_le,
        )
    db.add(prog)
    await db.commit()
    await db.refresh(session)
    await db.refresh(feedback)

    return {
        "session_id": str(session.id),
        "status": "finished",
        "score": session.score,
        "feedback": {
            "id": str(feedback.id),
            "session_id": str(feedback.session_id),
            "score_global": feedback.score_global,
            "points_forts": feedback.points_forts,
            "ameliorations": feedback.ameliorations,
            "recommandations": feedback.recommandations,
            "genere_le": feedback.genere_le.isoformat(),
        },
    }


def score_answer(question: dict | None, reponse: str) -> tuple[float, str, str, dict]:
    if question and question.get("type") == "qcm":
        correct_index = question.get("reponse_correcte")
        options = question.get("options", [])
        is_correct = False
        reponse = reponse.strip()
        try:
            submitted_index = int(reponse)
            if isinstance(correct_index, int):
                is_correct = submitted_index == correct_index
        except ValueError:
            if isinstance(correct_index, int) and 0 <= correct_index < len(options):
                is_correct = options[correct_index].lower() == reponse.lower()

        if is_correct:
            return (
                100.0,
                "Confident",
                f"Excellent, c'est la bonne reponse. {question.get('explication', '')}",
                {
                    "pertinence": 100,
                    "structure": 90,
                    "precision": 100,
                    "exemples": 80,
                    "profondeur": 90,
                },
            )

        correct_text = ""
        if isinstance(correct_index, int) and 0 <= correct_index < len(options):
            correct_text = options[correct_index]
        return (
            0.0,
            "Hesitant",
            f"La bonne reponse etait: {correct_text}. {question.get('explication', '')}",
            {
                "pertinence": 0,
                "structure": 30,
                "precision": 0,
                "exemples": 20,
                "profondeur": 20,
            },
        )

    word_count = len(reponse.split())
    lowered = reponse.lower()
    has_personal_role = any(token in lowered for token in ("je", "mon", "ma", "mes", "nous", "j'"))
    has_structure = any(token in lowered for token in ("situation", "tache", "action", "resultat", "d'abord", "ensuite", "enfin"))
    has_metrics = bool(re.search(r"\d|%|kpi|delai|cout|temps|score|taux", lowered))
    has_example = any(token in lowered for token in ("exemple", "projet", "cas", "experience", "client", "equipe"))
    has_tradeoff = any(token in lowered for token in ("risque", "limite", "compromis", "priorite", "arbitrage", "impact"))

    analysis = {
        "pertinence": min(100, 35 + word_count * 2),
        "structure": 80 if has_structure else (60 if word_count >= 25 else 40),
        "precision": 85 if has_metrics else (65 if word_count >= 30 else 45),
        "exemples": 85 if has_example else 45,
        "profondeur": 80 if has_tradeoff else (65 if word_count >= 35 else 45),
    }
    if has_personal_role:
        analysis["pertinence"] = min(100, analysis["pertinence"] + 10)

    score = round(sum(analysis.values()) / len(analysis), 1)
    if score < 55:
        return (
            score,
            "Hesitant",
            "Votre reponse est trop generale. Ajoutez votre role, un exemple concret et un resultat mesurable.",
            analysis,
        )
    if score < 75:
        return (
            score,
            "Neutral",
            "Bonne base. Renforcez la structure et precisez l'impact obtenu avec un chiffre ou un resultat.",
            analysis,
        )
    return (
        score,
        "Confident",
        "Reponse solide. Pour viser plus haut, explicitez aussi les risques, limites ou arbitrages.",
        analysis,
    )


async def generate_next_question(exercice: Exercice, reponses: list[dict], index: int, model: str | None = None) -> str:
    config = session_config(reponses)
    target_count = int(config.get("nombre_questions") or 10)
    sujet = config.get("sujet")
    user_reponses = user_responses(reponses)
    if len(user_reponses) >= target_count:
        return "Merci, vous avez termine toutes les questions. Cliquez sur Terminer pour obtenir votre bilan complet."

    questions = exercice.questions or []
    if index < len(questions):
        return questions[index].get("enonce") or fallback_question(exercice, index, reponses)

    try:
        ai_service = AIService(primary_model=model)
        previous = [r.get("texte", "") for r in user_reponses if r.get("texte")]
        question = await ai_service.generate_next_question(
            previous_responses=previous,
            domaine=exercice.domaine,
            niveau=exercice.difficulte,
            sujet=sujet,
            question_index=index,
            total_questions=target_count,
        )
        if question:
            return question
    except Exception:
        pass

    return fallback_question(exercice, index, reponses)


async def generate_feedback(exercice: Exercice | None, reponses: list[dict], score: float, model: str | None = None) -> dict:
    contexte = exercice.titre if exercice else "entretien"
    config = session_config(reponses)
    try:
        ai_service = AIService(primary_model=model)
        feedback = await ai_service.generate_feedback(
            user_responses(reponses),
            contexte,
            sujet=config.get("sujet"),
        )
        return normalize_feedback(feedback, score)
    except Exception:
        return fallback_feedback(score)


def fallback_question(exercice: Exercice, index: int, reponses: list[dict]) -> str:
    config = session_config(reponses)
    sujet = config.get("sujet")
    sujet_suffix = f" sur {sujet}" if sujet else ""
    questions = exercice.questions or []
    if index < len(questions):
        return questions[index].get("enonce") or "Pouvez-vous developper votre reponse ?"

    templates = {
        "TECHNIQUE": f"Pouvez-vous expliquer un compromis technique important{sujet_suffix} et sa complexite ?",
        "COMPORTEMENTAL": f"Quel resultat mesurable avez-vous obtenu{sujet_suffix}, et qu'auriez-vous fait differemment ?",
        "ETUDE_DE_CAS": f"Quels risques prioritaires surveilleriez-vous{sujet_suffix} pendant la mise en oeuvre ?",
        "SITUATIONNEL": f"Quelle serait votre premiere action concrete{sujet_suffix}, et pourquoi ?",
    }
    return templates.get(
        exercice.domaine,
        "Pouvez-vous donner un exemple concret pour illustrer votre raisonnement ?",
    )


def session_config(reponses: list[dict]) -> dict:
    for item in reponses:
        if item.get("type") == "system" and isinstance(item.get("simulation_config"), dict):
            return item["simulation_config"]
    return {}


def user_responses(reponses: list[dict]) -> list[dict]:
    return [item for item in reponses if item.get("type") != "system"]


def normalize_feedback(feedback: dict, fallback_score: float) -> dict:
    normalized = fallback_feedback(fallback_score)
    normalized["score_global"] = float(feedback.get("score_global") or fallback_score)
    for key in ("points_forts", "ameliorations"):
        items = feedback.get(key)
        if isinstance(items, list) and items:
            normalized[key] = [
                item if isinstance(item, dict) else {"domaine": "Analyse", "note": str(item), "score": 0.7}
                for item in items
            ]
    recommandations = feedback.get("recommandations")
    if isinstance(recommandations, list) and recommandations:
        normalized["recommandations"] = [str(item) for item in recommandations]
    return normalized


def split_stream_tokens(text: str) -> list[str]:
    parts = text.split(" ")
    tokens = []
    for index, part in enumerate(parts):
        suffix = " " if index < len(parts) - 1 else ""
        tokens.append(f"{part}{suffix}")
    return tokens or [text]


def fallback_feedback(score: float) -> dict:
    if score >= 80:
        return {
            "score_global": score,
            "points_forts": [
                {"domaine": "Communication", "note": "Expression claire et engageante.", "score": 0.9},
                {"domaine": "Structure", "note": "Reponses bien organisees et faciles a suivre.", "score": 0.85},
            ],
            "ameliorations": [
                {"domaine": "Precision", "note": "Ajouter davantage de chiffres et d'indicateurs d'impact.", "score": 0.75},
            ],
            "recommandations": [
                "Continuer avec des exercices de niveau Expert.",
                "Ajouter des KPI dans vos exemples pour renforcer votre impact.",
            ],
        }
    if score >= 60:
        return {
            "score_global": score,
            "points_forts": [
                {"domaine": "Fondamentaux", "note": "Les concepts principaux sont compris.", "score": 0.75},
            ],
            "ameliorations": [
                {"domaine": "Structure", "note": "Structurer les reponses avec la methode STAR.", "score": 0.55},
                {"domaine": "Confiance", "note": "Ralentir sur les passages complexes pour gagner en clarte.", "score": 0.6},
            ],
            "recommandations": [
                "Preparer 2 ou 3 exemples professionnels reutilisables.",
                "Reprendre les notions cles de l'exercice avant une nouvelle simulation.",
            ],
        }
    return {
        "score_global": score,
        "points_forts": [
            {"domaine": "Motivation", "note": "Bonne energie et volonte de progresser.", "score": 0.7},
        ],
        "ameliorations": [
            {"domaine": "Clarte", "note": "Developper les reponses avec plus de contexte et d'exemples.", "score": 0.4},
            {"domaine": "Technique", "note": "Revoir les notions principales abordees dans l'exercice.", "score": 0.45},
        ],
        "recommandations": [
            "Refaire l'exercice en notant les explications attendues.",
            "Utiliser la structure Situation, Tache, Action, Resultat pour chaque reponse ouverte.",
        ],
    }
