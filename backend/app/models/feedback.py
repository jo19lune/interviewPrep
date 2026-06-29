"""
Modèle SQLAlchemy pour l'entité Retour (Feedback).

Ce module définit la table `feedbacks` responsable du stockage
de l'analyse post-session générée par l'IA ou l'évaluateur.
"""

from datetime import datetime

from sqlalchemy import Column, DateTime, Float, ForeignKey, Index, JSON, Uuid
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class Retour(BaseModel):
    """
    Analyse et conseils générés après une session d'entretien.

    Cette table est liée en 1-1 avec une Session. Elle consolide le 
    score final, les points forts, les axes d'amélioration, ainsi 
    que les recommandations d'apprentissage pour l'utilisateur.

    Attributes:
        session_id (uuid.UUID): La clé étrangère pointant vers la session associée.
        score_global (float): L'évaluation quantitative finale de l'entretien.
        points_forts (list[str] | None): Liste JSON des compétences maîtrisées.
        ameliorations (list[str] | None): Liste JSON des faiblesses identifiées.
        recommandations (list[str] | None): Liste JSON des conseils d'apprentissage.
        genere_le (datetime): Horodatage de création du feedback.
        session (Session): Relation vers l'entité Session correspondante.
    """

    __tablename__ = "feedbacks"

    session_id = Column(
        Uuid(as_uuid=True), 
        ForeignKey("sessions.id"), 
        nullable=False, 
        unique=True, 
        index=True
    )
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
