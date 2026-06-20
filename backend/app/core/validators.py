"""
Validateurs réutilisables par les routes et services.

Ce module contient des fonctions utilitaires permettant de valider et 
normaliser les données d'entrée avant qu'elles ne soient traitées
par la logique métier.
"""

from fastapi import HTTPException, status


def normalize_enum_filter(value: str | None, allowed: set[str], field_name: str) -> str | None:
    """
    Normalise une valeur de filtre énumérée et vérifie sa validité.

    Cette fonction prend une chaîne de caractères, la nettoie, la convertit
    en majuscules et vérifie si elle fait partie d'un ensemble de valeurs
    autorisées. Si la valeur n'est pas autorisée, une exception HTTP 422 
    est levée avec un message clair.

    Args:
        value (str | None): La valeur brute à valider.
        allowed (set[str]): L'ensemble des valeurs autorisées (en majuscules).
        field_name (str): Le nom du champ testé, utilisé pour le message d'erreur.

    Returns:
        str | None: La chaîne de caractères normalisée, ou None si la valeur 
        initiale était None ou vide.

    Raises:
        HTTPException: Erreur 422 si la valeur normalisée n'est pas présente 
        dans l'ensemble `allowed`.
    """
    if value is None:
        return None

    normalized = value.strip().upper()
    if not normalized:
        return None
        
    if normalized not in allowed:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"{field_name} must be one of: {', '.join(sorted(allowed))}",
        )
        
    return normalized
