"""Résultats persistés des tests QA autonomes."""

from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Index, JSON, String, Uuid, Float

from app.models.base import BaseModel


class QAFeedback(BaseModel):
    """Snapshot d'une évaluation QA liée à son utilisateur."""

    __tablename__ = "qa_feedbacks"

    utilisateur_id = Column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    contexte = Column(String(255), nullable=False)
    sujet = Column(String(255), nullable=True)
    reponses = Column(JSON, nullable=False, default=list)
    score_global = Column(Float, nullable=False)
    points_forts = Column(JSON, nullable=False, default=list)
    ameliorations = Column(JSON, nullable=False, default=list)
    recommandations = Column(JSON, nullable=False, default=list)
    genere_le = Column(DateTime, default=datetime.utcnow, nullable=False)

    __table_args__ = (
        Index("idx_qa_feedbacks_user_created", "utilisateur_id", "cree_le"),
    )
