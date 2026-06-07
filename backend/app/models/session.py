"""Modele session."""

from datetime import datetime

from sqlalchemy import Column, DateTime, Float, ForeignKey, Index, JSON, String, Uuid
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class Session(BaseModel):
    """Session d'exercice lancee par un utilisateur."""

    __tablename__ = "sessions"

    utilisateur_id = Column(Uuid(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    exercice_id = Column(Uuid(as_uuid=True), ForeignKey("exercises.id"), nullable=False, index=True)

    commence_le = Column(DateTime, default=datetime.utcnow, nullable=False)
    termine_le = Column(DateTime, nullable=True)

    statut = Column(String, default="EN_ATTENTE", nullable=False)
    score = Column(Float, default=0.0, nullable=False)
    reponses = Column(JSON, nullable=True, default=list)

    utilisateur = relationship("User", back_populates="sessions")
    ia_simulation = relationship("SimulationIA", back_populates="session", uselist=False, cascade="all, delete-orphan")
    retour = relationship("Retour", back_populates="session", uselist=False, cascade="all, delete-orphan")

    __table_args__ = (
        Index("idx_sessions_utilisateur_id", "utilisateur_id"),
        Index("idx_sessions_exercice_id", "exercice_id"),
        Index("idx_sessions_statut", "statut"),
        Index("idx_sessions_commence_le", "commence_le"),
    )
