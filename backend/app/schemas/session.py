"""Schémas Pydantic pour sessions et feedback"""

from pydantic import BaseModel, ConfigDict
from typing import Optional, List, Any
from datetime import datetime
from uuid import UUID


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



