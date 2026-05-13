"""Schémas Pydantic pour exercices"""

from pydantic import BaseModel, Field
from typing import Optional, List, Any
from datetime import datetime
from uuid import UUID


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
    
    class Config:
        from_attributes = True


class ExerciceCreateRequest(BaseModel):
    """Requête de création d'exercice"""
    titre: str = Field(..., min_length=5, max_length=255)
    description: Optional[str] = None
    domaine: str
    difficulte: str
    duree_sec: int = Field(default=300, ge=60, le=3600)
    questions: List[Any]
    etiquettes: Optional[List[str]] = None
