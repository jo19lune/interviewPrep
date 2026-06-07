"""Modele feedback."""

from datetime import datetime

from sqlalchemy import Column, DateTime, Float, ForeignKey, Index, JSON, Uuid
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class Retour(BaseModel):
    """Analyse et conseils generes apres une session."""

    __tablename__ = "feedbacks"

    session_id = Column(Uuid(as_uuid=True), ForeignKey("sessions.id"), nullable=False, unique=True, index=True)
    score_global = Column(Float, nullable=False)

    points_forts = Column(JSON, nullable=True, default=list)
    ameliorations = Column(JSON, nullable=True, default=list)
    recommandations = Column(JSON, nullable=True, default=list)
    genere_le = Column(DateTime, default=datetime.utcnow, nullable=False)

    session = relationship("Session", back_populates="retour")

    __table_args__ = (
        Index("idx_feedbacks_session_id", "session_id"),
        Index("idx_feedbacks_score_global", "score_global"),
    )
