"""Schémas Pydantic pour validation/réponses utilisateur"""

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator
from typing import Optional
from datetime import datetime
from uuid import UUID


class UserRegisterRequest(BaseModel):
    """Requête de création de compte"""
    courriel: EmailStr
    mot_de_passe: str = Field(..., min_length=8, max_length=100)
    prenom: Optional[str] = None
    nom: Optional[str] = None


class UserLoginRequest(BaseModel):
    """Requête de connexion"""
    courriel: EmailStr
    mot_de_passe: str


class UserResponse(BaseModel):
    """Réponse utilisateur"""
    id: UUID
    courriel: str
    prenom: Optional[str] = None
    nom: Optional[str] = None
    domaine: Optional[str] = None
    niveau: Optional[str] = None
    est_actif: bool
    avatar_url: Optional[str] = None
    cree_le: datetime

    model_config = ConfigDict(from_attributes=True)


class UserProfileUpdate(BaseModel):
    """Mise à jour de profil"""
    prenom: Optional[str] = None
    nom: Optional[str] = None
    domaine: Optional[str] = None
    niveau: Optional[str] = None


class TokenRefreshRequest(BaseModel):
    """Requête de rafraîchissement de token"""
    refresh_token: str


class AuthResponse(BaseModel):
    """Réponse d'authentification avec tokens"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse
