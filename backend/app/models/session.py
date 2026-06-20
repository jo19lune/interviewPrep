"""
Modèle SQLAlchemy pour l'entité Session.

Ce module définit la table `sessions` qui enregistre chaque
tentative d'exercice (simulation d'entretien) effectuée par un utilisateur.
"""

from datetime import datetime

from sqlalchemy import Column, DateTime, Float, ForeignKey, Index, JSON, String, Uuid
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class Session(BaseModel):
    """
    Session d'exercice lancée par un utilisateur.

    Ce modèle fait le lien entre un utilisateur et un exercice spécifique.
    Il trace le cycle de vie de la session (début, fin, statut), stocke
    le score final, les réponses fournies, et gère les relations vers 
    la simulation IA et le feedback généré.

    Attributes:
        utilisateur_id (uuid.UUID): La clé étrangère pointant vers l'utilisateur.
        exercice_id (uuid.UUID): La clé étrangère pointant vers l'exercice.
        commence_le (datetime): Horodatage du début de la session.
        termine_le (datetime | None): Horodatage de fin de la session.
        statut (str): État de la session (ex: EN_ATTENTE, TERMINEE).
        score (float): Score global obtenu sur 100 ou 10.
        reponses (list[dict] | None): Historique ou liste des réponses.
        utilisateur (User): Relation vers le modèle Utilisateur.
        ia_simulation (SimulationIA): Relation vers les métadonnées de la simulation.
        retour (Retour): Relation vers le feedback ou l'analyse détaillée.
    """

    __tablename__ = "sessions"

    utilisateur_id = Column(
        Uuid(as_uuid=True), 
        ForeignKey("users.id"), 
        nullable=False, 
        index=True
    )
    exercice_id = Column(
        Uuid(as_uuid=True), 
        ForeignKey("exercises.id"), 
        nullable=False, 
        index=True
    )

    commence_le = Column(DateTime, default=datetime.utcnow, nullable=False)
    termine_le = Column(DateTime, nullable=True)

    statut = Column(String, default="EN_ATTENTE", nullable=False)
    score = Column(Float, default=0.0, nullable=False)
    reponses = Column(JSON, nullable=True, default=list)

    utilisateur = relationship("User", back_populates="sessions")
    ia_simulation = relationship(
        "SimulationIA", 
        back_populates="session", 
        uselist=False, 
        cascade="all, delete-orphan"
    )
    retour = relationship(
        "Retour", 
        back_populates="session", 
        uselist=False, 
        cascade="all, delete-orphan"
    )

    __table_args__ = (
        Index("idx_sessions_utilisateur_id", "utilisateur_id"),
        Index("idx_sessions_exercice_id", "exercice_id"),
        Index("idx_sessions_statut", "statut"),
        Index("idx_sessions_commence_le", "commence_le"),
    )
