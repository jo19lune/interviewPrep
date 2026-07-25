"""
Router pour la progression et le suivi statistique.

Ce module définit les endpoints permettant à un utilisateur de
consulter ses statistiques d'entraînement, son historique de 
sessions d'entretiens et son tableau de bord personnel.
"""

import os
import tempfile
from datetime import datetime
from typing import Any

from fastapi import APIRouter, Depends, Query
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.data.database import get_db
from app.models.user import User
from app.schemas.session import SessionResponse
from app.services import stats_service

router = APIRouter(prefix="/progress", tags=["progress"])


@router.get("/me")
async def get_my_progress(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict[str, Any]:
    """
    Récupère la progression personnelle globale de l'utilisateur courant.
    """
    return await stats_service.get_user_progress_stats(db, current_user.id)


@router.get("/stats")
async def get_detailed_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict[str, dict[str, Any]]:
    """
    Récupère les statistiques détaillées regroupées par domaine.
    """
    return await stats_service.get_user_detailed_stats(db, current_user.id)


@router.get("/history", response_model=list[SessionResponse])
async def get_session_history(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Récupère l'historique paginé des sessions de l'utilisateur.
    """
    sessions = await stats_service.get_user_session_history(db, current_user.id, skip, limit)
    return [SessionResponse.from_orm(s) for s in sessions]


@router.get("/export")
async def export_progress_pdf(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Exporte le rapport de progression au format PDF.
    """
    stats = await stats_service.get_user_progress_stats(db, current_user.id)
    detailed = await stats_service.get_user_detailed_stats(db, current_user.id)

    try:
        from reportlab.lib.pagesizes import A4
        from reportlab.lib.units import cm
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
        from reportlab.lib import colors

        fd, path = tempfile.mkstemp(suffix=".pdf")
        os.close(fd)

        doc = SimpleDocTemplate(path, pagesize=A4)
        styles = getSampleStyleSheet()
        elements = []

        elements.append(Paragraph(f"Rapport de progression - {current_user.prenom or ''} {current_user.nom or ''}", styles["Title"]))
        elements.append(Spacer(1, 0.5 * cm))
        elements.append(Paragraph(f"Généré le {datetime.utcnow().strftime('%d/%m/%Y %H:%M')}", styles["Normal"]))
        elements.append(Spacer(1, 1 * cm))

        elements.append(Paragraph("Résumé global", styles["Heading2"]))
        global_data = [
            ["Indicateur", "Valeur"],
            ["Score moyen", f"{stats.get('score_moyen', 0):.1f}/100"],
            ["Meilleur score", f"{stats.get('meilleur_score', 0):.1f}/100"],
            ["Sessions complétées", str(stats.get('total_sessions', 0))],
            ["Série actuelle", f"{stats.get('serie', 0)} jours"],
        ]
        t = Table(global_data, colWidths=[8*cm, 8*cm])
        t.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1A237E")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTSIZE", (0, 0), (-1, -1), 10),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ]))
        elements.append(t)
        elements.append(Spacer(1, 1 * cm))

        elements.append(Paragraph("Détail par domaine", styles["Heading2"]))
        domain_data = [["Domaine", "Sessions", "Score moyen", "Meilleur score"]]
        domain_rows = detailed.get("domaines", [])
        if isinstance(domain_rows, list) and domain_rows:
            for d in domain_rows:
                domain_data.append([
                    d.get("domaine", "N/A"),
                    str(d.get("sessions", 0)),
                    f"{d.get('score_moyen', 0):.1f}",
                    f"{d.get('meilleur_score', 0):.1f}",
                ])
        else:
            for key, val in domain_rows.items() if isinstance(domain_rows, dict) else []:
                domain_data.append([key, str(val.get("sessions", 0)), f"{val.get('score_moyen', 0):.1f}", f"{val.get('meilleur_score', 0):.1f}"])

        t2 = Table(domain_data, colWidths=[4*cm, 3*cm, 4*cm, 4*cm])
        t2.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1A237E")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTSIZE", (0, 0), (-1, -1), 9),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ]))
        elements.append(t2)

        doc.build(elements)
        return FileResponse(path, media_type="application/pdf", filename="rapport_progression.pdf")
    except ImportError:
        return {"message": "PDF generation library (reportlab) not installed. Install with: pip install reportlab", "url": None}
    except Exception as e:
        return {"message": f"PDF generation failed: {str(e)}", "url": None}
