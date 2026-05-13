"""Modèle progression"""

from sqlalchemy import Column, String, Float, Integer, ForeignKey, DateTime, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.models.base import BaseModel


class Progression(BaseModel):
    """Modèle Progression - Statistiques consolidées par utilisateur et domaine"""
    __tablename__ = "progress"
    
    # Clé étrangère
    utilisateur_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, unique=True, index=True)
    
    # Classification
    domaine = Column(String, nullable=True)  # Enum comme string
    
    # Statistiques
    total_sessions = Column(Integer, default=0, nullable=False)
    score_moyen = Column(Float, default=0.0, nullable=False)
    meilleur_score = Column(Float, default=0.0, nullable=False)
    
    # Engagement
    serie = Column(Integer, default=0, nullable=False)  # Nombre de jours consécutifs
    derniere_session_le = Column(DateTime, nullable=True)
    
    # Relation
    utilisateur = relationship("User", back_populates="progression")
    
    # Index
    __table_args__ = (
        Index('idx_progress_utilisateur_id', 'utilisateur_id'),
        Index('idx_progress_domaine', 'domaine'),
    )
