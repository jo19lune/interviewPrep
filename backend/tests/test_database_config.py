import pytest

from app.data.database import normalize_async_database_url


def test_normalize_neon_url_for_asyncpg():
    url = normalize_async_database_url(
        "postgresql://user:password@ep-example-pooler.eu-central-1.aws.neon.tech/"
        "interviewprep?sslmode=require"
    )

    assert url.startswith("postgresql+asyncpg://")
    assert "ssl=require" in url
    assert "sslmode=" not in url


def test_strip_channel_binding_param_for_asyncpg():
    url = normalize_async_database_url(
        "postgresql://user:password@ep-example-pooler.eu-central-1.aws.neon.tech/"
        "interviewprep?sslmode=require&channel_binding=prefer"
    )

    assert url.startswith("postgresql+asyncpg://")
    assert "ssl=require" in url
    assert "sslmode=" not in url
    assert "channel_binding" not in url


def test_keep_sqlite_test_url():
    url = normalize_async_database_url("sqlite+aiosqlite:///:memory:")

    assert url == "sqlite+aiosqlite:///:memory:"


def test_reject_unsupported_database_driver():
    with pytest.raises(ValueError, match="asyncpg or SQLite"):
        normalize_async_database_url("mysql://user:password@localhost/db")
