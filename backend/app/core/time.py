"""Helpers for consistent UTC timestamps."""

from datetime import datetime, timezone


def utc_now() -> datetime:
    """Return the current UTC time as a naive datetime for legacy DB columns."""
    return datetime.now(timezone.utc).replace(tzinfo=None)
