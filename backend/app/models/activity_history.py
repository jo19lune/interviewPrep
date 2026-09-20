"""Modèle SQLAlchemy pour l'historique des activités utilisateur."""

from sqlalchemy import Column, ForeignKey, Index, JSON, String, Uuid
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class ActivityHistory(BaseModel):
    """Entrée d'historique d'activité associée à un utilisateur."""

    __tablename__ = "activity_histories"

    utilisateur_id = Column(
        Uuid(as_uuid=True),
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )
    type = Column("type", String(80), nullable=False, index=True)
    message = Column(String(500), nullable=False)
    metadata_ = Column("metadata", JSON, nullable=True, default=dict)

    utilisateur = relationship("User", back_populates="activity_histories")

    __table_args__ = (
        Index("idx_activity_histories_user_created", "utilisateur_id", "cree_le"),
        Index("idx_activity_histories_type", "type"),
    )
