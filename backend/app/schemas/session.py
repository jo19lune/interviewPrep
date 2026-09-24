"""Schémas Pydantic pour sessions et feedback"""

from pydantic import BaseModel, ConfigDict, field_validator
from typing import Optional, List, Any
from datetime import datetime
from uuid import UUID

from app.config.settings import settings


class SessionResponse(BaseModel):
    """Réponse session"""
    id: UUID
    utilisateur_id: UUID
    exercice_id: UUID
    commence_le: datetime
    termine_le: Optional[datetime] = None
    statut: str
    score: float
    reponses: Optional[List[Any]] = None

    model_config = ConfigDict(from_attributes=True)


class SessionCreateRequest(BaseModel):
    """Requête de démarrage de session"""
    exercice_id: UUID
    subject: Optional[str] = None
    question_count: int = 10
    model: Optional[str] = None

    @field_validator("model")
    @classmethod
    def validate_model(cls, v: Optional[str]) -> Optional[str]:
        """Rejette tout modèle non exposé par le sélecteur /simulation/models."""
        if v is None:
            return v
        allowed = settings.openai_models or []
        if v not in allowed:
            raise ValueError(
                f"Unknown AI model '{v}'. Allowed models: "
                + (", ".join(allowed) if allowed else "none configured")
            )
        return v



