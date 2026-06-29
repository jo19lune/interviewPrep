"""Schemas Pydantic pour les flux d'authentification."""

from pydantic import BaseModel, EmailStr, Field, field_validator


class ForgotPasswordRequest(BaseModel):
    courriel: EmailStr
    
    @field_validator('courriel')
    @classmethod
    def sanitize_email(cls, v: str) -> str:
        return v.strip().lower()


class VerifyResetCodeRequest(BaseModel):
    courriel: EmailStr
    code: str = Field(..., min_length=6, max_length=6)

    @field_validator('courriel')
    @classmethod
    def sanitize_email(cls, v: str) -> str:
        return v.strip().lower()


class ResetPasswordRequest(BaseModel):
    courriel: EmailStr
    code: str = Field(..., min_length=6, max_length=6)
    nouveau_mot_de_passe: str = Field(..., min_length=8, max_length=100)

    @field_validator('courriel')
    @classmethod
    def sanitize_email(cls, v: str) -> str:
        return v.strip().lower()

    @field_validator('nouveau_mot_de_passe')
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        if not any(char.isdigit() for char in v):
            raise ValueError('Le mot de passe doit contenir au moins un chiffre.')
        if not any(char.isalpha() for char in v):
            raise ValueError('Le mot de passe doit contenir au moins une lettre.')
        if not any(char in "!@#$%^&*()_+-=[]{}|;:,.<>?/" for char in v):
            raise ValueError('Le mot de passe doit contenir au moins un caractère spécial.')
        return v
