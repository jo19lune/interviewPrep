"""Schémas Pydantic pour feedback"""

from pydantic import BaseModel
from typing import Optional, List, Any
from datetime import datetime
from uuid import UUID


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
