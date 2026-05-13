"""Modèle simulation IA"""

from sqlalchemy import Column, String, Integer, Float, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.models.base import BaseModel


class SimulationIA(BaseModel):
    """Modèle SimulationIA - Paramètres spécifiques à l'IA pour une session"""
    __tablename__ = "ai_simulations"
    
    # Clé étrangère
    session_id = Column(UUID(as_uuid=True), ForeignKey("sessions.id"), nullable=False, unique=True, index=True)
    
    # Configuration du modèle
    modele = Column(String, default="gpt-4", nullable=False)  # gpt-4, claude-3.5, mistral, etc.
    
    # Tokens
    jetons_prompt = Column(Integer, nullable=True)  # Nombre de tokens utilisés pour la requête
    jetons_reponse = Column(Integer, nullable=True)  # Nombre de tokens utilisés pour la réponse
    
    # Paramètres
    temperature = Column(Float, default=0.7, nullable=False)  # Entre 0 et 1, contrôle la créativité
    
    # Relation
    session = relationship("Session", back_populates="ia_simulation")
    
    # Index
    __table_args__ = (
        Index('idx_ai_simulations_session_id', 'session_id'),
        Index('idx_ai_simulations_modele', 'modele'),
    )
