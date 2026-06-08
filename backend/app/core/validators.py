"""Validateurs reutilisables par les routes et services."""

from fastapi import HTTPException, status


def normalize_enum_filter(value: str | None, allowed: set[str], field_name: str) -> str | None:
    """Normaliser une valeur de filtre enum et lever une erreur API claire."""
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
