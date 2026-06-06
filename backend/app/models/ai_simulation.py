"""Modele simulation IA."""

from sqlalchemy import Column, Float, ForeignKey, Index, Integer, String, Uuid
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class SimulationIA(BaseModel):
    """Parametres IA associes a une session."""

    __tablename__ = "ai_simulations"

    session_id = Column(Uuid(as_uuid=True), ForeignKey("sessions.id"), nullable=False, unique=True, index=True)
    modele = Column(String, default="claude-3-5-sonnet-20241022", nullable=False)

    jetons_prompt = Column(Integer, nullable=True)
    jetons_reponse = Column(Integer, nullable=True)
    temperature = Column(Float, default=0.7, nullable=False)

    session = relationship("Session", back_populates="ia_simulation")

    __table_args__ = (
        Index("idx_ai_simulations_session_id", "session_id"),
        Index("idx_ai_simulations_modele", "modele"),
    )
