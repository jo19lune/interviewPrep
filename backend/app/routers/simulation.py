"""Router simulation IA - Gestion des sessions de simulation avec IA"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from datetime import datetime
from uuid import UUID

from app.data.database import get_db
from app.models.user import User
from app.models.session import Session
from app.models.exercice import Exercice
from app.models.feedback import Retour
from app.models.ai_simulation import SimulationIA
from app.core.security import get_current_user
from app.services.ai_service import AIService
from app.config.settings import settings

router = APIRouter(prefix="/simulation", tags=["simulation"])


@router.post("/start")
async def start_simulation(
    exercice_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Démarrer une nouvelle simulation IA"""
    # Vérifier que l'exercice existe
    result = await db.execute(
        select(Exercice).where(Exercice.id == exercice_id)
    )
    exercice = result.scalars().first()
    
    if not exercice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercise not found"
        )
    
    # Créer une session
    session = Session(
        utilisateur_id=current_user.id,
        exercice_id=exercice_id,
        commence_le=datetime.utcnow(),
        statut="EN_COURS"
    )
    
    # Créer la simulation IA associée
    ia_sim = SimulationIA(
        modele="claude-3-5-sonnet-20241022",
        temperature=0.7
    )
    session.ia_simulation = ia_sim
    
    db.add(session)
    db.add(ia_sim)
    await db.commit()
    await db.refresh(session)
    
    return {
        "session_id": session.id,
        "status": "started",
        "exercise_title": exercice.titre
    }


@router.post("/answer")
async def submit_answer(
    session_id: UUID,
    reponse: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Soumettre une réponse dans la simulation"""
    # Vérifier la session
    result = await db.execute(
        select(Session).where(
            (Session.id == session_id) & 
            (Session.utilisateur_id == current_user.id)
        )
    )
    session = result.scalars().first()
    
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
    
    if session.statut != "EN_COURS":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Session is not active"
        )
    
    # Ajouter la réponse à la session
    if session.reponses is None:
        session.reponses = []
    
    session.reponses.append({
        "texte": reponse,
        "timestamp": datetime.utcnow().isoformat(),
        "index": len(session.reponses)
    })
    
    db.add(session)
    await db.commit()
    await db.refresh(session)
    
    return {
        "status": "received",
        "answer_count": len(session.reponses)
    }


@router.get("/stream/{session_id}")
async def stream_ai_response(
    session_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Streaming de la réponse IA en temps réel (SSE)
    """
    # Vérifier la session
    result = await db.execute(
        select(Session).where(
            (Session.id == session_id) & 
            (Session.utilisateur_id == current_user.id)
        )
    )
    session = result.scalars().first()
    
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
    
    # TODO: Implémenter streaming avec Claude API
    # Cela nécessite streaming.with_streaming_response
    return {"message": "Streaming not yet implemented"}


@router.post("/finish/{session_id}")
async def finish_simulation(
    session_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Terminer une simulation et générer le feedback"""
    # Vérifier la session
    result = await db.execute(
        select(Session).where(
            (Session.id == session_id) & 
            (Session.utilisateur_id == current_user.id)
        )
    )
    session = result.scalars().first()
    
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
    
    # Mettre à jour le statut
    session.statut = "TERMINEE"
    session.termine_le = datetime.utcnow()
    
    # TODO: Générer le feedback avec IA
    # feedback = await ai_service.generate_feedback(session.reponses, ...)
    
    feedback = Retour(
        session_id=session.id,
        score_global=75.0,
        points_forts=[{"domaine": "Communication", "note": "Bonne structure"}],
        ameliorations=[{"domaine": "Exemples", "note": "Plus d'exemples concrets"}],
        recommandations=["Pratiquer la méthode STAR", "Améliorer clarté"]
    )
    
    db.add(session)
    db.add(feedback)
    await db.commit()
    await db.refresh(session)
    
    return {
        "session_id": session.id,
        "status": "finished",
        "score": session.score
    }
