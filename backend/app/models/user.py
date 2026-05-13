"""Modèle utilisateur"""

from sqlalchemy import Column, String, Boolean, Enum, Index
from sqlalchemy.orm import relationship
from app.models.base import BaseModel
from app.core.enums import Domaine, Niveau


class User(BaseModel):
    """Modèle Utilisateur - Comptes et informations de profil"""
    __tablename__ = "users"
    
    # Informations de compte
    courriel = Column(String(255), unique=True, index=True, nullable=False)
    mot_de_passe_hash = Column(String(255), nullable=False)
    
    # Informations personnelles
    prenom = Column(String(100), nullable=True)
    nom = Column(String(100), nullable=True)
    
    # Profil professionnel
    domaine = Column(Enum(Domaine), nullable=True)
    niveau = Column(Enum(Niveau), nullable=True)
    
    # Statut
    est_actif = Column(Boolean, default=True, nullable=False)
    
    # Relations
    sessions = relationship("Session", back_populates="utilisateur", cascade="all, delete-orphan")
    progression = relationship("Progression", back_populates="utilisateur", uselist=False, cascade="all, delete-orphan")
    
    # Index
    __table_args__ = (
        Index('idx_users_email', 'courriel'),
        Index('idx_users_actif', 'est_actif'),
    )
