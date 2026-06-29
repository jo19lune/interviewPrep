import time
from typing import Dict, Tuple

from fastapi import HTTPException, status
from app.config.settings import settings

login_attempts: Dict[str, Tuple[int, float]] = {}


def check_rate_limit(key: str) -> None:
    now = time.time()
    if key in login_attempts:
        attempts, last_attempt = login_attempts[key]
        if attempts >= settings.max_attempts:
            if now - last_attempt < settings.lockout_time:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Trop de tentatives de connexion. Veuillez réessayer plus tard.",
                )
            else:
                login_attempts[key] = (0, now)
    else:
        login_attempts[key] = (0, now)


def record_failed_attempt(key: str) -> None:
    now = time.time()
    if key in login_attempts:
        attempts, _ = login_attempts[key]
        login_attempts[key] = (attempts + 1, now)
    else:
        login_attempts[key] = (1, now)


def clear_attempts(key: str) -> None:
    if key in login_attempts:
        del login_attempts[key]
