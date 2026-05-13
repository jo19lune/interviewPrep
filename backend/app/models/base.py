"""Modèle de base pour toutes les entités"""

import uuid
from datetime import datetime
from sqlalchemy import Column, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class BaseModel(Base):
    """Classe de base pour tous les modèles avec UUID et timestamps"""
    __abstract__ = True
    
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        nullable=False
    )
    cree_le = Column(DateTime, default=datetime.utcnow, nullable=False)
    modifie_le = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
