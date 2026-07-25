"""initial_migration

Revision ID: 0d944a319cef
Revises: 
Create Date: 2026-05-19 16:50:31.571577

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '0d944a319cef'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table('users',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('courriel', sa.VARCHAR(length=255), nullable=False),
        sa.Column('mot_de_passe_hash', sa.VARCHAR(length=255), nullable=False),
        sa.Column('prenom', sa.VARCHAR(length=100), nullable=True),
        sa.Column('nom', sa.VARCHAR(length=100), nullable=True),
        sa.Column('domaine', postgresql.ENUM('TECHNIQUE', 'COMPORTEMENTAL', 'SITUATIONNEL', 'ETUDE_DE_CAS', 'MOTIVATION', name='domaine'), nullable=True),
        sa.Column('niveau', postgresql.ENUM('DEBUTANT', 'INTERMEDIAIRE', 'AVANCE', 'EXPERT', name='niveau'), nullable=True),
        sa.Column('est_actif', sa.BOOLEAN(), nullable=False),
        sa.Column('avatar_url', sa.VARCHAR(length=500), nullable=True),
        sa.Column('reset_code', sa.VARCHAR(length=64), nullable=True),
        sa.Column('reset_code_expires_at', postgresql.TIMESTAMP(), nullable=True),
        sa.Column('cree_le', postgresql.TIMESTAMP(), nullable=False),
        sa.Column('modifie_le', postgresql.TIMESTAMP(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_users_courriel', 'users', ['courriel'], unique=True)
    op.create_index('idx_users_email', 'users', ['courriel'], unique=False)
    op.create_index('idx_users_actif', 'users', ['est_actif'], unique=False)

    op.create_table('exercises',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('titre', sa.VARCHAR(length=255), nullable=False),
        sa.Column('description', sa.VARCHAR(length=1000), nullable=True),
        sa.Column('domaine', sa.VARCHAR(), nullable=False),
        sa.Column('difficulte', sa.VARCHAR(), nullable=False),
        sa.Column('duree_sec', sa.INTEGER(), nullable=False),
        sa.Column('questions', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('etiquettes', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('difficulte_estimee', sa.INTEGER(), nullable=True),
        sa.Column('cree_le', postgresql.TIMESTAMP(), nullable=False),
        sa.Column('modifie_le', postgresql.TIMESTAMP(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_exercises_titre', 'exercises', ['titre'], unique=False)
    op.create_index('ix_exercises_domaine', 'exercises', ['domaine'], unique=False)
    op.create_index('ix_exercises_difficulte', 'exercises', ['difficulte'], unique=False)
    op.create_index('idx_exercises_domaine', 'exercises', ['domaine'], unique=False)
    op.create_index('idx_exercises_difficulte', 'exercises', ['difficulte'], unique=False)

    op.create_table('sessions',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('utilisateur_id', sa.UUID(), nullable=False),
        sa.Column('exercice_id', sa.UUID(), nullable=False),
        sa.Column('commence_le', postgresql.TIMESTAMP(), nullable=False),
        sa.Column('termine_le', postgresql.TIMESTAMP(), nullable=True),
        sa.Column('statut', sa.VARCHAR(), nullable=False),
        sa.Column('score', sa.DOUBLE_PRECISION(precision=53), nullable=False),
        sa.Column('reponses', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('cree_le', postgresql.TIMESTAMP(), nullable=False),
        sa.Column('modifie_le', postgresql.TIMESTAMP(), nullable=False),
        sa.ForeignKeyConstraint(['exercice_id'], ['exercises.id'], name='sessions_exercice_id_fkey'),
        sa.ForeignKeyConstraint(['utilisateur_id'], ['users.id'], name='sessions_utilisateur_id_fkey'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_sessions_utilisateur_id', 'sessions', ['utilisateur_id'], unique=False)
    op.create_index('ix_sessions_exercice_id', 'sessions', ['exercice_id'], unique=False)
    op.create_index('idx_sessions_utilisateur_id', 'sessions', ['utilisateur_id'], unique=False)
    op.create_index('idx_sessions_statut', 'sessions', ['statut'], unique=False)
    op.create_index('idx_sessions_exercice_id', 'sessions', ['exercice_id'], unique=False)
    op.create_index('idx_sessions_commence_le', 'sessions', ['commence_le'], unique=False)

    op.create_table('feedbacks',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('session_id', sa.UUID(), nullable=False),
        sa.Column('score_global', sa.DOUBLE_PRECISION(precision=53), nullable=False),
        sa.Column('points_forts', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('ameliorations', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('recommandations', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('genere_le', postgresql.TIMESTAMP(), nullable=False),
        sa.Column('cree_le', postgresql.TIMESTAMP(), nullable=False),
        sa.Column('modifie_le', postgresql.TIMESTAMP(), nullable=False),
        sa.ForeignKeyConstraint(['session_id'], ['sessions.id'], name='feedbacks_session_id_fkey'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_feedbacks_session_id', 'feedbacks', ['session_id'], unique=True)
    op.create_index('idx_feedbacks_session_id', 'feedbacks', ['session_id'], unique=False)
    op.create_index('idx_feedbacks_score_global', 'feedbacks', ['score_global'], unique=False)

    op.create_table('progress',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('utilisateur_id', sa.UUID(), nullable=False),
        sa.Column('domaine', sa.VARCHAR(), nullable=True),
        sa.Column('total_sessions', sa.INTEGER(), nullable=False),
        sa.Column('score_moyen', sa.DOUBLE_PRECISION(precision=53), nullable=False),
        sa.Column('meilleur_score', sa.DOUBLE_PRECISION(precision=53), nullable=False),
        sa.Column('serie', sa.INTEGER(), nullable=False),
        sa.Column('derniere_session_le', postgresql.TIMESTAMP(), nullable=True),
        sa.Column('cree_le', postgresql.TIMESTAMP(), nullable=False),
        sa.Column('modifie_le', postgresql.TIMESTAMP(), nullable=False),
        sa.ForeignKeyConstraint(['utilisateur_id'], ['users.id'], name='progress_utilisateur_id_fkey'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_progress_utilisateur_id', 'progress', ['utilisateur_id'], unique=True)
    op.create_index('idx_progress_utilisateur_id', 'progress', ['utilisateur_id'], unique=False)
    op.create_index('idx_progress_domaine', 'progress', ['domaine'], unique=False)

    op.create_table('ai_simulations',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('session_id', sa.UUID(), nullable=False),
        sa.Column('modele', sa.VARCHAR(), nullable=False),
        sa.Column('jetons_prompt', sa.INTEGER(), nullable=True),
        sa.Column('jetons_reponse', sa.INTEGER(), nullable=True),
        sa.Column('temperature', sa.DOUBLE_PRECISION(precision=53), nullable=False),
        sa.Column('cree_le', postgresql.TIMESTAMP(), nullable=False),
        sa.Column('modifie_le', postgresql.TIMESTAMP(), nullable=False),
        sa.ForeignKeyConstraint(['session_id'], ['sessions.id'], name='ai_simulations_session_id_fkey'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_ai_simulations_session_id', 'ai_simulations', ['session_id'], unique=True)
    op.create_index('idx_ai_simulations_session_id', 'ai_simulations', ['session_id'], unique=False)
    op.create_index('idx_ai_simulations_modele', 'ai_simulations', ['modele'], unique=False)

    op.create_table('token_blocklist',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('token_jti', sa.VARCHAR(length=255), nullable=False),
        sa.Column('type_token', sa.VARCHAR(length=50), nullable=False),
        sa.Column('revoked_at', postgresql.TIMESTAMP(), nullable=True),
        sa.Column('cree_le', postgresql.TIMESTAMP(), nullable=False),
        sa.Column('modifie_le', postgresql.TIMESTAMP(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_token_blocklist_jti', 'token_blocklist', ['token_jti'], unique=True)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table('token_blocklist')
    op.drop_table('ai_simulations')
    op.drop_table('progress')
    op.drop_table('feedbacks')
    op.drop_table('sessions')
    op.drop_table('exercises')
    op.drop_table('users')
