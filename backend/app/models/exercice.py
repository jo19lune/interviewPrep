"""
Modèle SQLAlchemy pour l'entité Exercice.

Ce module définit la table `exercises` qui stocke les informations 
relatives au contenu pédagogique utilisé pour les simulations d'entretien.
"""

from sqlalchemy import Column, Index, Integer, JSON, String

from app.models.base import BaseModel


class Exercice(BaseModel):
    """
    Contenu pédagogique utilisé par les simulations.

    Ce modèle contient la définition d'un exercice d'entretien, avec son 
    titre, sa description, ses questions formatées en JSON, ainsi que sa 
    catégorisation (domaine et difficulté).

    Attributes:
        titre (str): Le titre principal de l'exercice.
        description (str | None): Une brève description du scénario de l'exercice.
        domaine (str): Le domaine de compétence (ex: TECHNIQUE, COMPORTEMENTAL).
        difficulte (str): Le niveau de difficulté (ex: DEBUTANT, AVANCE).
        duree_sec (int): La durée suggérée pour l'exercice en secondes (défaut: 300).
        questions (list[dict]): Les questions associées à cet exercice sous forme de liste JSON.
        etiquettes (list[str] | None): Des tags optionnels en JSON pour faciliter la recherche.
        difficulte_estimee (int | None): Une évaluation numérique de la difficulté.
    """

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
