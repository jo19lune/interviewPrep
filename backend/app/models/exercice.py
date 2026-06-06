"""Modele exercice."""

from sqlalchemy import Column, Index, Integer, JSON, String

from app.models.base import BaseModel


class Exercice(BaseModel):
    """Contenu pedagogique utilise par les simulations."""

    __tablename__ = "exercises"

    titre = Column(String(255), nullable=False, index=True)
    description = Column(String(1000), nullable=True)

    domaine = Column(String, nullable=False, index=True)
    difficulte = Column(String, nullable=False, index=True)
    duree_sec = Column(Integer, default=300, nullable=False)

    questions = Column(JSON, nullable=False, default=list)
    etiquettes = Column(JSON, nullable=True, default=list)
    difficulte_estimee = Column(Integer, nullable=True)

    __table_args__ = (
        Index("idx_exercises_domaine", "domaine"),
        Index("idx_exercises_difficulte", "difficulte"),
    )
