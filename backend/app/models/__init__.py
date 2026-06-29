"""
Module d'exportation des modèles de la base de données.

Ce module regroupe et expose toutes les classes de modèles SQLAlchemy de
l'application. Cela permet d'importer plus facilement les modèles depuis
d'autres parties de l'application (ex: `from app.models import User`) et 
garantit qu'ils sont tous enregistrés dans l'objet `Base.metadata` pour 
les migrations Alembic.
"""

from app.models.ai_simulation import SimulationIA
from app.models.exercice import Exercice
from app.models.feedback import Retour
from app.models.progression import Progression
from app.models.session import Session
from app.models.user import User

__all__ = [
    "Exercice",
    "Progression",
    "Retour",
    "Session",
    "SimulationIA",
    "User",
]
