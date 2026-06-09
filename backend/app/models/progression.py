"""
Modèle SQLAlchemy pour l'entité Progression.

Ce module définit la table `progress` qui sert à stocker de manière 
consolidée les statistiques globales et les habitudes d'apprentissage 
d'un utilisateur sur la plateforme.
"""

from sqlalchemy import Column, DateTime, Float, ForeignKey, Index, Integer, String, Uuid
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class Progression(BaseModel):
    """
    Modèle Progression - Statistiques consolidées par utilisateur.

    Stocke les données agrégées telles que le nombre total de sessions, 
    le score moyen et la série de jours consécutifs d'utilisation (streak)
    pour offrir des statistiques globales sans requêter tout l'historique.

    Attributes:
        utilisateur_id (uuid.UUID): Clé étrangère unique vers l'utilisateur.
        domaine (str | None): Le domaine de prédilection ou courant.
        total_sessions (int): Le nombre total de sessions terminées.
        score_moyen (float): Le score moyen sur l'ensemble des sessions.
        meilleur_score (float): Le meilleur score historique obtenu.
        serie (int): La série de jours consécutifs de pratique (streak).
        derniere_session_le (datetime | None): Horodatage de la dernière session.
        utilisateur (User): Relation 1-1 vers le modèle Utilisateur.
    """
    
    __tablename__ = "progress"
    
    # Clé étrangère
    utilisateur_id = Column(
        Uuid(as_uuid=True), 
        ForeignKey("users.id"), 
        nullable=False, 
        unique=True, 
        index=True
    )
    
    # Classification
    domaine = Column(String, nullable=True)
    
    # Statistiques
    total_sessions = Column(Integer, default=0, nullable=False)
    score_moyen = Column(Float, default=0.0, nullable=False)
    meilleur_score = Column(Float, default=0.0, nullable=False)
    
    # Engagement
    serie = Column(Integer, default=0, nullable=False)
    derniere_session_le = Column(DateTime, nullable=True)
    
    # Relation
    utilisateur = relationship("User", back_populates="progression")
    
    # Index
    __table_args__ = (
        Index('idx_progress_utilisateur_id', 'utilisateur_id'),
        Index('idx_progress_domaine', 'domaine'),
    )
