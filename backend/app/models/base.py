"""
Modèle de base SQLAlchemy pour toutes les entités de l'application.

Ce module définit la classe `BaseModel` dont héritent tous les modèles
de la base de données. Elle fournit des attributs communs tels qu'un 
identifiant unique (UUID) et des horodatages de création et de modification.
"""

import uuid

from sqlalchemy import Column, DateTime, Uuid
from sqlalchemy.orm import declarative_base

from app.core.time import utc_now

Base = declarative_base()


class BaseModel(Base):
    """
    Classe de base abstraite pour tous les modèles SQLAlchemy.

    Cette classe ne crée pas de table en soi (`__abstract__ = True`).
    Elle ajoute automatiquement à toutes les tables enfants une clé
    primaire UUID (`id`) et les colonnes de suivi temporel (`cree_le` 
    et `modifie_le`).

    Attributes:
        id (uuid.UUID): L'identifiant unique universel de l'enregistrement.
        cree_le (datetime): La date et l'heure de création (UTC).
        modifie_le (datetime): La date et l'heure de la dernière modification (UTC).
    """

    __abstract__ = True

    id = Column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        nullable=False,
    )
    cree_le = Column(
        DateTime, 
        default=utc_now,
        nullable=False
    )
    modifie_le = Column(
        DateTime, 
        default=utc_now,
        onupdate=utc_now,
        nullable=False
    )
