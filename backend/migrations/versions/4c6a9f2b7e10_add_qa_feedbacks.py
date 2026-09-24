"""add persisted QA feedbacks

Revision ID: 4c6a9f2b7e10
Revises: 0d944a319cef
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "4c6a9f2b7e10"
down_revision: Union[str, Sequence[str], None] = "0d944a319cef"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "qa_feedbacks",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("utilisateur_id", sa.UUID(), nullable=False),
        sa.Column("contexte", sa.String(length=255), nullable=False),
        sa.Column("sujet", sa.String(length=255), nullable=True),
        sa.Column("reponses", sa.JSON(), nullable=False),
        sa.Column("score_global", sa.Float(), nullable=False),
        sa.Column("points_forts", sa.JSON(), nullable=False),
        sa.Column("ameliorations", sa.JSON(), nullable=False),
        sa.Column("recommandations", sa.JSON(), nullable=False),
        sa.Column("genere_le", sa.DateTime(), nullable=False),
        sa.Column("cree_le", sa.DateTime(), nullable=False),
        sa.Column("modifie_le", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["utilisateur_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_qa_feedbacks_utilisateur_id", "qa_feedbacks", ["utilisateur_id"])
    op.create_index(
        "idx_qa_feedbacks_user_created",
        "qa_feedbacks",
        ["utilisateur_id", "cree_le"],
    )


def downgrade() -> None:
    op.drop_index("idx_qa_feedbacks_user_created", table_name="qa_feedbacks")
    op.drop_index("ix_qa_feedbacks_utilisateur_id", table_name="qa_feedbacks")
    op.drop_table("qa_feedbacks")
