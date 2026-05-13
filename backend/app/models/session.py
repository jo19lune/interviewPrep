"""Modèle session"""

from sqlalchemy import Column, String, Float, ForeignKey, DateTime, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from datetime import datetime
from app.models.base import BaseModel


class Session(BaseModel):
    """Modèle Session - Sessions d'exercices lancées par l'utilisateur"""
    __tablename__ = "sessions"
    
    # Clés étrangères
    utilisateur_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    exercice_id = Column(UUID(as_uuid=True), ForeignKey("exercises.id"), nullable=False, index=True)
    
    # Timing
    commence_le = Column(DateTime, default=datetime.utcnow, nullable=False)
    termine_le = Column(DateTime, nullable=True)
    
    # Statut et score
    statut = Column(String, default="EN_ATTENTE", nullable=False)  # StatutSession enum as string
    score = Column(Float, default=0.0, nullable=False)
    
    # Contenu
    # Structure: [{ "question_index": 0, "reponse": "...", "timestamp": "...", "score_partiel": 0.8 }, ...]
    reponses = Column(JSONB, nullable=True, default=list)
    
    # Relations
    utilisateur = relationship("User", back_populates="sessions")
    ia_simulation = relationship("SimulationIA", back_populates="session", uselist=False, cascade="all, delete-orphan")
    retour = relationship("Retour", back_populates="session", uselist=False, cascade="all, delete-orphan")
    
    # Index
    __table_args__ = (
        Index('idx_sessions_utilisateur_id', 'utilisateur_id'),
        Index('idx_sessions_exercice_id', 'exercice_id'),
        Index('idx_sessions_statut', 'statut'),
        Index('idx_sessions_commence_le', 'commence_le'),
    )
