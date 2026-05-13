"""Schémas Pydantic pour sessions et feedback"""

from pydantic import BaseModel, Field
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
    
    class Config:
        from_attributes = True


class SessionCreateRequest(BaseModel):
    """Requête de démarrage de session"""
    exercice_id: UUID


class FeedbackResponse(BaseModel):
    """Réponse feedback"""
    id: UUID
    session_id: UUID
    score_global: float
    points_forts: Optional[List[Any]] = None
    ameliorations: Optional[List[Any]] = None
    recommandations: Optional[List[str]] = None
    genere_le: datetime
    
    class Config:
        from_attributes = True
