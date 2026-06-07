"""Modele de base pour toutes les entites."""

import uuid
from datetime import datetime

from sqlalchemy import Column, DateTime, Uuid
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class BaseModel(Base):
    """Classe de base pour tous les modeles avec UUID et timestamps."""

    __abstract__ = True

    id = Column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        nullable=False,
    )
    cree_le = Column(DateTime, default=datetime.utcnow, nullable=False)
    modifie_le = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
