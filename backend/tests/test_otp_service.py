import pytest
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.models.base import Base
from app.models.email_otp import EmailOTP  # noqa: F401
from app.services.otp_service import consume_otp, issue_otp


@pytest.mark.asyncio
async def test_otp_is_single_use_and_rejects_wrong_code():
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:", poolclass=StaticPool,
        connect_args={"check_same_thread": False},
    )
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    factory = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with factory() as db:
        code = await issue_otp(db, "otp@example.com", "login_2fa")
        assert not await consume_otp(db, "otp@example.com", "login_2fa", "000000" if code != "000000" else "000001")
        assert await consume_otp(db, "otp@example.com", "login_2fa", code)
        assert not await consume_otp(db, "otp@example.com", "login_2fa", code)
    await engine.dispose()
