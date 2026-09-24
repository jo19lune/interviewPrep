"""add activity histories

Revision ID: 7f2c1d4a9b6e
Revises: 4c6a9f2b7e10
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "7f2c1d4a9b6e"
down_revision: Union[str, Sequence[str], None] = "4c6a9f2b7e10"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "activity_histories",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("utilisateur_id", sa.UUID(), nullable=False),
        sa.Column("type", sa.String(length=80), nullable=False),
        sa.Column("message", sa.String(length=500), nullable=False),
        sa.Column("metadata", sa.JSON(), nullable=True),
        sa.Column("cree_le", sa.DateTime(), nullable=False),
        sa.Column("modifie_le", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["utilisateur_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_activity_histories_utilisateur_id",
        "activity_histories",
        ["utilisateur_id"],
    )
    op.create_index(
        "ix_activity_histories_type",
        "activity_histories",
        ["type"],
    )
    op.create_index(
        "idx_activity_histories_user_created",
        "activity_histories",
        ["utilisateur_id", "cree_le"],
    )
    op.create_index(
        "idx_activity_histories_type",
        "activity_histories",
        ["type"],
    )


def downgrade() -> None:
    op.drop_index("idx_activity_histories_type", table_name="activity_histories")
    op.drop_index(
        "idx_activity_histories_user_created",
        table_name="activity_histories",
    )
    op.drop_index(
        "ix_activity_histories_type",
        table_name="activity_histories",
    )
    op.drop_index(
        "ix_activity_histories_utilisateur_id",
        table_name="activity_histories",
    )
    op.drop_table("activity_histories")
