"""Service d'intégration avec Claude AI"""

import anthropic
from typing import Optional
import logging

logger = logging.getLogger(__name__)


class AIService:
    """Service pour interagir avec Claude AI"""
    
    def __init__(self, api_key: str):
        self.client = anthropic.Anthropic(api_key=api_key)
    
    async def generate_feedback(
        self,
        reponses: list[dict],
        contexte: str,
        temperature: float = 0.7
    ) -> dict:
        """
        Générer un feedback basé sur les réponses
        
        Args:
            reponses: Liste des réponses de l'utilisateur
            contexte: Contexte de l'exercice/domaine
            temperature: Paramètre de créativité (0-1)
        
        Returns:
            dict contenant score_global, points_forts, ameliorations, recommandations
        """
        prompt = self._build_feedback_prompt(reponses, contexte)
        
        try:
            message = self.client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=1024,
                temperature=temperature,
                messages=[
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            )
            
            # Parser la réponse Claude
            response_text = message.content[0].text
            feedback = self._parse_feedback_response(response_text)
            return feedback
            
        except Exception as e:
            logger.error(f"Error generating feedback: {e}")
            raise
    
    async def generate_next_question(
        self,
        previous_responses: list[str],
        domaine: str,
        niveau: str,
        temperature: float = 0.7
    ) -> str:
        """
        Générer la prochaine question adaptée
        
        Args:
            previous_responses: Réponses précédentes pour adaptation
            domaine: Domaine de l'entretien
            niveau: Niveau de difficulté
            temperature: Paramètre de créativité
        
        Returns:
            La prochaine question à poser
        """
        prompt = self._build_question_prompt(previous_responses, domaine, niveau)
        
        try:
            message = self.client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=500,
                temperature=temperature,
                messages=[
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            )
            
            return message.content[0].text
            
        except Exception as e:
            logger.error(f"Error generating question: {e}")
            raise
    
    def _build_feedback_prompt(self, reponses: list, contexte: str) -> str:
        """Construire le prompt pour générer le feedback"""
        reponses_text = "\n".join([f"- {r.get('texte', '')}" for r in reponses])
        
        return f"""Analyse les réponses suivantes données lors d'un entretien d'embauche dans le domaine {contexte}:

{reponses_text}

Fournis une analyse structurée JSON avec:
- score_global: note de 0 à 100
- points_forts: liste des points forts observés
- ameliorations: liste des axes d'amélioration
- recommandations: liste des conseils pratiques

Réponds en JSON valide uniquement."""
    
    def _build_question_prompt(self, previous_responses: list, domaine: str, niveau: str) -> str:
        """Construire le prompt pour la prochaine question"""
        responses_context = ""
        if previous_responses:
            responses_context = f"\n\nRéponses précédentes pour adaptation:\n" + \
                              "\n".join([f"- {r[:200]}..." for r in previous_responses[-3:]])
        
        return f"""Tu es un recruteur expérimenté en entretiens d'embauche.

Domaine: {domaine}
Niveau candidat: {niveau}
{responses_context}

Pose une question de suivi pertinente et adaptée au niveau du candidat.
La question doit être professionnelle, claire et pertinente pour le domaine."""
    
    def _parse_feedback_response(self, response_text: str) -> dict:
        """Parser la réponse du feedback depuis Claude"""
        import json
        
        try:
            # Essayer d'extraire JSON de la réponse
            import re
            json_match = re.search(r'\{.*\}', response_text, re.DOTALL)
            if json_match:
                feedback = json.loads(json_match.group())
                return feedback
        except (json.JSONDecodeError, AttributeError):
            pass
        
        # Fallback: retourner une structure par défaut
        return {
            "score_global": 75.0,
            "points_forts": ["Bonne clarté d'expression"],
            "ameliorations": ["Approfondir les exemples"],
            "recommandations": ["Pratiquer la méthode STAR"]
        }
