"""Schémas Pydantic pour exercices"""

from pydantic import BaseModel, ConfigDict, Field, field_validator
from typing import Optional, List, Any
from datetime import datetime
from uuid import UUID

from app.core.enums import Domaine, Niveau


class ExerciceResponse(BaseModel):
    """Réponse exercice"""
    id: UUID
    titre: str
    description: Optional[str] = None
    domaine: str
    difficulte: str
    duree_sec: int
    questions: List[Any]  # JSONB - structure flexible
    etiquettes: Optional[List[str]] = None
    cree_le: datetime

    model_config = ConfigDict(from_attributes=True)


class ExerciceCreateRequest(BaseModel):
    """Requête de création d'exercice"""
    titre: str = Field(..., min_length=5, max_length=255)
    description: Optional[str] = None
    domaine: str
    difficulte: str
    duree_sec: int = Field(default=300, ge=60, le=3600)
    questions: List[Any]
    etiquettes: Optional[List[str]] = None

    @field_validator("domaine")
    @classmethod
    def validate_domaine(cls, value: str) -> str:
        normalized = value.strip().upper()
        allowed = {item.value for item in Domaine}
        if normalized not in allowed:
            raise ValueError(f"domaine must be one of: {', '.join(sorted(allowed))}")
        return normalized

    @field_validator("difficulte")
    @classmethod
    def validate_difficulte(cls, value: str) -> str:
        normalized = value.strip().upper()
        allowed = {item.value for item in Niveau}
        if normalized not in allowed:
            raise ValueError(f"difficulte must be one of: {', '.join(sorted(allowed))}")
        return normalized
