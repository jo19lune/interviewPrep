"""
Modèle SQLAlchemy pour l'entité SimulationIA.

Ce module définit la table `ai_simulations` qui conserve les 
métadonnées et paramètres des modèles d'intelligence artificielle
utilisés lors d'une session d'entretien.
"""

from sqlalchemy import Column, Float, ForeignKey, Index, Integer, String, Uuid
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class SimulationIA(BaseModel):
    """
    Paramètres IA associés à une session d'exercice.

    Stocke les détails techniques liés à l'appel API de l'IA générative 
    durant l'exercice, comme le modèle utilisé, la température (créativité),
    et la consommation de tokens (jetons).

    Attributes:
        session_id (uuid.UUID): Clé étrangère unique vers la session associée.
        modele (str): Identifiant du modèle utilisé (ex: gpt-4, claude-3).
        jetons_prompt (int | None): Nombre de jetons consommés en entrée.
        jetons_reponse (int | None): Nombre de jetons générés en sortie.
        temperature (float): Degré de créativité du modèle, généralement entre 0 et 1.
        session (Session): Relation vers l'entité Session.
    """

    __tablename__ = "ai_simulations"

    session_id = Column(
        Uuid(as_uuid=True), 
        ForeignKey("sessions.id"), 
        nullable=False, 
        unique=True, 
        index=True
    )
    modele = Column(
        String, 
        default="claude-3-5-sonnet-20241022", 
        nullable=False
    )

    jetons_prompt = Column(Integer, nullable=True)
    jetons_reponse = Column(Integer, nullable=True)
    temperature = Column(Float, default=0.7, nullable=False)

    session = relationship("Session", back_populates="ia_simulation")

    __table_args__ = (
        Index("idx_ai_simulations_session_id", "session_id"),
        Index("idx_ai_simulations_modele", "modele"),
    )
