"""Modèle feedback"""

from sqlalchemy import Column, Float, ForeignKey, DateTime, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from datetime import datetime
from app.models.base import BaseModel


class Retour(BaseModel):
    """Modèle Retour (Feedback) - Analyse et conseils générés après une session"""
    __tablename__ = "feedbacks"
    
    # Clé étrangère
    session_id = Column(UUID(as_uuid=True), ForeignKey("sessions.id"), nullable=False, unique=True, index=True)
    
    # Scoring
    score_global = Column(Float, nullable=False)
    
    # Analyse détaillée (JSONB)
    # points_forts: [{"domaine": "Communication", "note": "Vous avez structuré votre réponse...", "score": 0.9}]
    points_forts = Column(JSONB, nullable=True, default=list)
    
    # ameliorations: [{"domaine": "Exemples", "note": "Manque d'exemples concrets...", "score": 0.6}]
    ameliorations = Column(JSONB, nullable=True, default=list)
    
    # recommandations: ["Travaillez la méthode STAR", "Pratiquez plus d'études de cas"]
    recommandations = Column(JSONB, nullable=True, default=list)
    
    # Timing
    genere_le = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relation
    session = relationship("Session", back_populates="retour")
    
    # Index
    __table_args__ = (
        Index('idx_feedbacks_session_id', 'session_id'),
        Index('idx_feedbacks_score_global', 'score_global'),
    )
