from pydantic import BaseModel
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
    reponses: List[QAReponseItem]
    contexte: str
    sujet: Optional[str] = None
