"""Modèle exercice"""

from sqlalchemy import Column, String, Integer, JSON, Index
from sqlalchemy.dialects.postgresql import JSONB
from app.models.base import BaseModel


class Exercice(BaseModel):
    """Modèle Exercice - Contenu pédagogique (QCM, Études de cas, etc.)"""
    __tablename__ = "exercises"
    
    # Informations de base
    titre = Column(String(255), nullable=False, index=True)
    description = Column(String(1000), nullable=True)
    
    # Classification
    domaine = Column(String, nullable=False, index=True)  # Enum as string
    difficulte = Column(String, nullable=False, index=True)  # Enum as string
    
    # Contenu
    duree_sec = Column(Integer, default=300, nullable=False)  # Durée en secondes
    
    # Données JSONB pour flexibilité
    # Structure: [{ "type": "qcm" | "case" | "logique" | "ouverte", "enonce": "...", ... }]
    questions = Column(JSONB, nullable=False, default=list)
    
    # Métadonnées
    # Structure: ["python", "REST API", "gestion d'équipe", ...]
    etiquettes = Column(JSONB, nullable=True, default=list)
    
    # Audit
    difficulte_estimee = Column(Integer, nullable=True)  # Score de difficulté calculé
    
    # Index
    __table_args__ = (
        Index('idx_exercises_domaine', 'domaine'),
        Index('idx_exercises_difficulte', 'difficulte'),
    )
