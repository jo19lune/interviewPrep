"""Persistent, single-use email OTPs."""

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Index, Integer, String
from app.models.base import BaseModel


class EmailOTP(BaseModel):
    __tablename__ = "email_otps"

    email = Column(String(255), nullable=False, index=True)
    user_id = Column(ForeignKey("users.id", ondelete="CASCADE"), nullable=True, index=True)
    purpose = Column(String(40), nullable=False)
    code_hash = Column(String(128), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    attempts = Column(Integer, nullable=False, default=0)
    max_attempts = Column(Integer, nullable=False, default=5)
    consumed = Column(Boolean, nullable=False, default=False)

    __table_args__ = (
        Index("idx_email_otps_lookup", "email", "purpose", "consumed", "expires_at"),
    )
