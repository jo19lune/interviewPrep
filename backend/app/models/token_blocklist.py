"""
Modèle SQLAlchemy pour la Blocklist de tokens JWT.

Ce module permet de stocker les tokens révoqués (ex: lors d'une déconnexion)
afin d'empêcher leur réutilisation avant leur date d'expiration naturelle.
"""

from datetime import datetime

from sqlalchemy import Column, DateTime, String, Index
from app.models.base import BaseModel


class TokenBlocklist(BaseModel):
    """
    Modèle pour les tokens révoqués.
    
    Attributes:
        token (str): Le JWT complet qui a été révoqué.
        created_at (datetime): Date de révocation du token.
    """
    
    __tablename__ = "token_blocklist"
    
    token = Column(String, unique=True, index=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    __table_args__ = (
        Index("idx_token_blocklist_token", "token"),
    )
