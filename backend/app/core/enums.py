"""Énumérations pour l'application InterviewPrep"""

from enum import Enum


class Domaine(str, Enum):
    """Domaines de compétences pour les exercices et progression"""
    TECHNIQUE = "TECHNIQUE"
    COMPORTEMENTAL = "COMPORTEMENTAL"
    SITUATIONNEL = "SITUATIONNEL"
    ETUDE_DE_CAS = "ETUDE_DE_CAS"
    MOTIVATION = "MOTIVATION"


class Niveau(str, Enum):
    """Niveaux de difficulté"""
    DEBUTANT = "DEBUTANT"
    INTERMEDIAIRE = "INTERMEDIAIRE"
    AVANCE = "AVANCE"
    EXPERT = "EXPERT"


class StatutSession(str, Enum):
    """Statuts possibles pour une session d'exercice"""
    EN_ATTENTE = "EN_ATTENTE"
    EN_COURS = "EN_COURS"
    EN_PAUSE = "EN_PAUSE"
    TERMINEE = "TERMINEE"
    ANNULEE = "ANNULEE"
    ABANDONNEE = "ABANDONNEE"
