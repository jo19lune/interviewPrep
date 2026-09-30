"""Endpoints publics de récupération du mot de passe."""

import asyncio
import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rate_limit import check_rate_limit, clear_attempts, record_failed_attempt
from app.data.database import get_db
from app.schemas.auth import ForgotPasswordRequest, ResetPasswordRequest, VerifyResetCodeRequest
from app.services.email_service import EmailDeliveryError
from app.services.password_reset_service import (
    reset_user_password,
    send_password_reset_code_if_user_exists,
    verify_password_reset_code,
)

router = APIRouter(prefix="/auth", tags=["authentication"])
logger = logging.getLogger(__name__)


@router.post("/forgot-password")
async def forgot_password(
    request: ForgotPasswordRequest,
    request_info: Request,
    db: AsyncSession = Depends(get_db),
):
    """Envoie le code de réinitialisation.

    L'envoi est effectué **en ligne** : la réponse ne renvoie 200 que si le
    transport a réellement accepté l'email. En cas d'échec d'envoi, un 503 est
    renvoyé pour que l'application n'affiche pas « Code envoyé » à tort.
    Le cas « compte inexistant » reste volontairement non révélateur (200).
    """
    client_ip = request_info.client.host if request_info.client else "unknown"
    rate_limit_key = f"forgot_{client_ip}"
    check_rate_limit(rate_limit_key)
    try:
        result = await send_password_reset_code_if_user_exists(db, request.courriel)
    except EmailDeliveryError:
        logger.exception(
            "Password reset email delivery failed for %s", request.courriel
        )
        record_failed_attempt(rate_limit_key)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "Le service d'envoi d'email est indisponible. "
                "Aucun code n'a été envoyé, réessayez dans quelques instants."
            ),
            headers={"Retry-After": "60"},
        )

    if not result.get("sent"):
        record_failed_attempt(rate_limit_key)
        await asyncio.sleep(0.5)
        return {
            "message": "Si ce compte existe, un code de reinitialisation a ete envoye."
        }
    clear_attempts(rate_limit_key)
    return {
        "message": "Code de reinitialisation envoye a votre adresse email.",
        "expires_in_minutes": result.get("expires_in_minutes"),
    }


@router.post("/verify-reset-code")
async def verify_reset_code(
    request: VerifyResetCodeRequest, db: AsyncSession = Depends(get_db)
):
    valid = await verify_password_reset_code(db, request.courriel, request.code)
    if not valid:
        await asyncio.sleep(1)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code invalide ou expire.",
        )
    return {"valid": True}


@router.post("/reset-password")
async def reset_password(
    request: ResetPasswordRequest, db: AsyncSession = Depends(get_db)
):
    ok = await reset_user_password(
        db, request.courriel, request.code, request.nouveau_mot_de_passe
    )
    if not ok:
        await asyncio.sleep(1)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code invalide ou expire.",
        )
    return {"message": "Mot de passe reinitialise avec succes."}
