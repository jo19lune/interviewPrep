"""
Modèle SQLAlchemy pour l'entité Utilisateur.

Ce module définit la table `users` qui stocke les informations 
d'authentification, le profil professionnel et les préférences 
de l'utilisateur, ainsi que ses relations avec d'autres entités.
"""

from sqlalchemy import Boolean, Column, DateTime, Enum, Index, String
from sqlalchemy.orm import relationship

from app.core.enums import Domaine, Niveau
from app.models.base import BaseModel


class User(BaseModel):
    """
    Modèle de données représentant un compte utilisateur.

    Stocke les informations personnelles, professionnelles (domaine 
    et niveau) et d'authentification. Il maintient également des 
    relations avec les sessions d'entretien et la progression globale
    de l'utilisateur.

    Attributes:
        courriel (str): L'adresse email unique servant d'identifiant (login).
        mot_de_passe_hash (str): Le hash sécurisé du mot de passe.
        prenom (str | None): Le prénom de l'utilisateur.
        nom (str | None): Le nom de famille de l'utilisateur.
        domaine (Domaine | None): Le domaine professionnel de l'utilisateur.
        niveau (Niveau | None): Le niveau d'expertise professionnel.
        est_actif (bool): Indique si le compte est actif (True) ou suspendu (False).
        avatar_url (str | None): L'URL ou le chemin de l'image de profil.
        reset_code (str | None): Le code de réinitialisation de mot de passe (6 chiffres).
        reset_code_expires_at (str | None): L'horodatage d'expiration du code de reset.
        sessions (list[Session]): Relation 1-N vers les sessions d'entretien de l'utilisateur.
        progression (Progression): Relation 1-1 vers les statistiques de progression.
    """
    
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
    
    # Avatar
    avatar_url = Column(String(512), nullable=True)
    
    # Reset mot de passe
    reset_code = Column(String(6), nullable=True)
    reset_code_expires_at = Column(DateTime, nullable=True)
    
    # Relations
    sessions = relationship(
        "Session", 
        back_populates="utilisateur", 
        cascade="all, delete-orphan"
    )
    progression = relationship(
        "Progression", 
        back_populates="utilisateur", 
        uselist=False, 
        cascade="all, delete-orphan"
    )
    
    # Index
    __table_args__ = (
        Index('idx_users_email', 'courriel'),
        Index('idx_users_actif', 'est_actif'),
    )
