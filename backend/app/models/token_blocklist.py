"""Modèle SQLAlchemy pour la blocklist des tokens JWT."""

from sqlalchemy import Column, DateTime, Index, String

from app.models.base import BaseModel


class TokenBlocklist(BaseModel):
    __tablename__ = "token_blocklist"

    token_jti = Column(String(length=255), nullable=False)
    type_token = Column(String(length=50), nullable=False)
    revoked_at = Column(DateTime, nullable=True)

    __table_args__ = (
        Index("ix_token_blocklist_jti", "token_jti", unique=True),
    )
