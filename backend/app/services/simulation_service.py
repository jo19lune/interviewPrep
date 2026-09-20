"""Façade de compatibilité du service de simulation."""

from .simulation_ai import fallback_question, generate_feedback, generate_next_question
from .simulation_helpers import (
    fallback_feedback,
    normalize_feedback,
    score_answer,
    session_config,
    split_stream_tokens,
    user_responses,
)
from .simulation_operations import (
    cancel_active_session,
    create_simulation_session,
    finish_session_and_generate_feedback,
    process_user_answer,
)

__all__ = [
    "cancel_active_session", "create_simulation_session",
    "finish_session_and_generate_feedback", "process_user_answer",
    "generate_feedback", "generate_next_question", "score_answer",
    "session_config", "split_stream_tokens", "user_responses",
    "normalize_feedback", "fallback_feedback", "fallback_question",
]
