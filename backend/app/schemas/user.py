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

    @field_validator('courriel')
    @classmethod
    def sanitize_email(cls, v: str) -> str:
        return v.strip().lower()

    @field_validator('prenom', 'nom')
    @classmethod
    def sanitize_names(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            return v.strip()
        return v

    @field_validator('mot_de_passe')
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        if not any(char.isdigit() for char in v):
            raise ValueError('Le mot de passe doit contenir au moins un chiffre.')
        if not any(char.isalpha() for char in v):
            raise ValueError('Le mot de passe doit contenir au moins une lettre.')
        if not any(char in "!@#$%^&*()_+-=[]{}|;:,.<>?/" for char in v):
            raise ValueError('Le mot de passe doit contenir au moins un caractère spécial.')
        return v

class UserLoginRequest(BaseModel):
    """Requête de connexion"""
    courriel: EmailStr
    mot_de_passe: str

    @field_validator('courriel')
    @classmethod
    def sanitize_email(cls, v: str) -> str:
        return v.strip().lower()


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


class ChangePasswordRequest(BaseModel):
    """Requête de changement de mot de passe"""
    mot_de_passe_actuel: str
    nouveau_mot_de_passe: str = Field(..., min_length=8, max_length=100)

    @field_validator('nouveau_mot_de_passe')
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        if not any(char.isdigit() for char in v):
            raise ValueError('Le nouveau mot de passe doit contenir au moins un chiffre.')
        if not any(char.isalpha() for char in v):
            raise ValueError('Le nouveau mot de passe doit contenir au moins une lettre.')
        if not any(char in "!@#$%^&*()_+-=[]{}|;:,.<>?/" for char in v):
            raise ValueError('Le nouveau mot de passe doit contenir au moins un caractère spécial.')
        return v


class TokenRefreshRequest(BaseModel):
    """Requête de rafraîchissement de token"""
    refresh_token: str


class AuthResponse(BaseModel):
    """Réponse d'authentification avec tokens"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse


class LoginResponse(BaseModel):
    requires_2fa: bool = False
    challenge_expires_in_seconds: Optional[int] = None
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    token_type: str = "bearer"
    user: Optional[UserResponse] = None
