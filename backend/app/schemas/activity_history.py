"""Schémas Pydantic pour l'historique des activités."""

from __future__ import annotations

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import AliasChoices, BaseModel, ConfigDict, Field, model_validator


class ActivityHistoryResponse(BaseModel):
    id: UUID
    utilisateur_id: UUID
    type: str
    message: str
    metadata: dict[str, Any] | None = Field(
        default=None,
        validation_alias=AliasChoices("metadata_", "metadata"),
        serialization_alias="metadata",
    )
    cree_le: datetime
    modifie_le: datetime

    model_config = ConfigDict(from_attributes=True)


class ActivityHistoryCreateRequest(BaseModel):
    type: str = Field(min_length=1, max_length=80)
    message: str = Field(min_length=1, max_length=500)
    metadata: dict[str, Any] | None = Field(
        default=None,
        validation_alias=AliasChoices("metadata_", "metadata"),
        serialization_alias="metadata",
    )

    @model_validator(mode="after")
    def validate_text_fields(self) -> "ActivityHistoryCreateRequest":
        if not self.type.strip():
            raise ValueError("Le type d'activité est obligatoire.")
        if not self.message.strip():
            raise ValueError("Le message d'activité est obligatoire.")
        return self


class ActivityHistoryUpdateRequest(BaseModel):
    type: str | None = Field(default=None, max_length=80)
    message: str | None = Field(default=None, max_length=500)
    metadata: dict[str, Any] | None = None

    @model_validator(mode="after")
    def validate_update(self) -> "ActivityHistoryUpdateRequest":
        if self.type is None and self.message is None and self.metadata is None:
            raise ValueError("Au moins un champ doit être fourni.")
        if self.type is not None and not self.type.strip():
            raise ValueError("Le type d'activité est invalide.")
        if self.message is not None and not self.message.strip():
            raise ValueError("Le message d'activité est invalide.")
        return self
