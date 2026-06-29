"""
Énumérations pour l'application InterviewPrep.

Ce module contient les définitions des énumérations utilisées dans
toute l'application pour garantir la cohérence des types (niveaux,
domaines, statuts).
"""

from enum import Enum


class Domaine(str, Enum):
    """
    Domaines de compétences pour les exercices et la progression.

    Définit les différentes catégories d'entretiens ou de questions.
    Hérite de `str` pour assurer la sérialisation en JSON.
    """
    TECHNIQUE = "TECHNIQUE"
    COMPORTEMENTAL = "COMPORTEMENTAL"
    SITUATIONNEL = "SITUATIONNEL"
    ETUDE_DE_CAS = "ETUDE_DE_CAS"
    MOTIVATION = "MOTIVATION"


class Niveau(str, Enum):
    """
    Niveaux de difficulté.

    Catégorise les utilisateurs et les exercices par niveau
    d'expertise attendu.
    """
    DEBUTANT = "DEBUTANT"
    INTERMEDIAIRE = "INTERMEDIAIRE"
    AVANCE = "AVANCE"
    EXPERT = "EXPERT"


class StatutSession(str, Enum):
    """
    Statuts possibles pour une session d'exercice.

    Représente le cycle de vie d'une simulation d'entretien pour un
    utilisateur.
    """
    EN_ATTENTE = "EN_ATTENTE"
    EN_COURS = "EN_COURS"
    EN_PAUSE = "EN_PAUSE"
    TERMINEE = "TERMINEE"
    ANNULEE = "ANNULEE"
    ABANDONNEE = "ABANDONNEE"
