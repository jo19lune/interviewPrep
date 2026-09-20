from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field
from typing import List, Optional

class NextQuestionRequest(BaseModel):
    previous_responses: List[str]
    domaine: str
    difficulte: str
    sujet: Optional[str] = None
    question_index: int
    total_questions: int


class ScoreAnswerRequest(BaseModel):
    question: str
    answer: str


class QAReponseItem(BaseModel):
    id: Optional[str] = None
    text: str
    is_user: bool
    timestamp: str


class FeedbackRequest(BaseModel):
    reponses: List[QAReponseItem] = Field(min_length=1, max_length=200)
    contexte: str = Field(min_length=1, max_length=255)
    sujet: Optional[str] = None


class QAFeedbackResponse(BaseModel):
    id: UUID
    score_global: float
    points_forts: list[dict]
    ameliorations: list[dict]
    recommandations: list[str]
    genere_le: datetime

    model_config = ConfigDict(from_attributes=True)
