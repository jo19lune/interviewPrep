"""add google auth and reusable email OTPs"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "9b7c8d6e5f4a"
down_revision: Union[str, Sequence[str], None] = "7f2c1d4a9b6e"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("users") as batch:
        batch.alter_column("mot_de_passe_hash", existing_type=sa.String(length=255), nullable=True)
        batch.add_column(sa.Column("google_subject", sa.String(length=255), nullable=True))
        batch.create_unique_constraint("uq_users_google_subject", ["google_subject"])
        batch.create_index("ix_users_google_subject", ["google_subject"], unique=False)
    op.create_table(
        "email_otps",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=True),
        sa.Column("purpose", sa.String(length=40), nullable=False),
        sa.Column("code_hash", sa.String(length=128), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("attempts", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("max_attempts", sa.Integer(), nullable=False, server_default="5"),
        sa.Column("consumed", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("cree_le", sa.DateTime(), nullable=False),
        sa.Column("modifie_le", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_email_otps_email", "email_otps", ["email"])
    op.create_index("ix_email_otps_user_id", "email_otps", ["user_id"])
    op.create_index("idx_email_otps_lookup", "email_otps", ["email", "purpose", "consumed", "expires_at"])


def downgrade() -> None:
    op.drop_index("idx_email_otps_lookup", table_name="email_otps")
    op.drop_index("ix_email_otps_user_id", table_name="email_otps")
    op.drop_index("ix_email_otps_email", table_name="email_otps")
    op.drop_table("email_otps")
    with op.batch_alter_table("users") as batch:
        batch.drop_index("ix_users_google_subject")
        batch.drop_constraint("uq_users_google_subject", type_="unique")
        batch.drop_column("google_subject")
        batch.alter_column("mot_de_passe_hash", existing_type=sa.String(length=255), nullable=False)
