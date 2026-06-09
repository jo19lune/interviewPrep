"""
Exceptions personnalisées de l'application.

Ce module définit une hiérarchie d'exceptions spécifiques au domaine 
de l'application InterviewPrep. Elles permettent de lever des erreurs
métier avec des codes HTTP appropriés qui seront interceptés par le 
gestionnaire d'exceptions global de FastAPI.
"""

from fastapi import status


class AppException(Exception):
    """
    Exception de base pour l'application.

    Toutes les autres exceptions personnalisées de l'application doivent
    hériter de cette classe.

    Attributes:
        message (str): Le message d'erreur descriptif.
        status_code (int): Le code de statut HTTP associé à l'erreur.
    """

    def __init__(self, message: str, status_code: int = status.HTTP_400_BAD_REQUEST):
        """
        Initialise une AppException.

        Args:
            message (str): La description de l'erreur.
            status_code (int, optional): Le code HTTP à renvoyer.
                Par défaut à 400 (Bad Request).
        """
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class AuthenticationError(AppException):
    """
    Erreur d'authentification.

    Levée lorsque les informations d'identification d'un utilisateur 
    sont invalides ou manquantes (ex: mauvais mot de passe).
    Renvoie un statut HTTP 401 Unauthorized.
    """

    def __init__(self, message: str = "Authentication failed"):
        """
        Initialise une AuthenticationError.

        Args:
            message (str, optional): Message d'erreur personnalisé.
                Par défaut à "Authentication failed".
        """
        super().__init__(message, status.HTTP_401_UNAUTHORIZED)


class AuthorizationError(AppException):
    """
    Erreur d'autorisation.

    Levée lorsqu'un utilisateur authentifié tente d'accéder à une 
    ressource pour laquelle il n'a pas les droits nécessaires.
    Renvoie un statut HTTP 403 Forbidden.
    """

    def __init__(self, message: str = "Access denied"):
        """
        Initialise une AuthorizationError.

        Args:
            message (str, optional): Message d'erreur personnalisé.
                Par défaut à "Access denied".
        """
        super().__init__(message, status.HTTP_403_FORBIDDEN)


class ValidationError(AppException):
    """
    Erreur de validation.

    Levée lorsque les données fournies par l'utilisateur ne respectent 
    pas les règles métier ou de format attendues.
    Renvoie un statut HTTP 422 Unprocessable Entity.
    """

    def __init__(self, message: str = "Validation failed"):
        """
        Initialise une ValidationError.

        Args:
            message (str, optional): Message d'erreur personnalisé.
                Par défaut à "Validation failed".
        """
        super().__init__(message, status.HTTP_422_UNPROCESSABLE_ENTITY)


class NotFoundError(AppException):
    """
    Ressource non trouvée.

    Levée lorsqu'une entité demandée (ex: utilisateur, exercice) 
    n'existe pas dans le système.
    Renvoie un statut HTTP 404 Not Found.
    """

    def __init__(self, message: str = "Resource not found"):
        """
        Initialise une NotFoundError.

        Args:
            message (str, optional): Message d'erreur personnalisé.
                Par défaut à "Resource not found".
        """
        super().__init__(message, status.HTTP_404_NOT_FOUND)


class ConflictError(AppException):
    """
    Erreur de conflit.

    Levée lors d'une tentative de création ou modification qui entre en
    conflit avec l'état actuel du système (ex: adresse email déjà utilisée).
    Renvoie un statut HTTP 409 Conflict.
    """

    def __init__(self, message: str = "Conflict"):
        """
        Initialise une ConflictError.

        Args:
            message (str, optional): Message d'erreur personnalisé.
                Par défaut à "Conflict".
        """
        super().__init__(message, status.HTTP_409_CONFLICT)


class InternalServerError(AppException):
    """
    Erreur interne du serveur.

    Levée lors d'une défaillance inattendue ou critique du système, 
    comme une panne de base de données.
    Renvoie un statut HTTP 500 Internal Server Error.
    """

    def __init__(self, message: str = "Internal server error"):
        """
        Initialise une InternalServerError.

        Args:
            message (str, optional): Message d'erreur personnalisé.
                Par défaut à "Internal server error".
        """
        super().__init__(message, status.HTTP_500_INTERNAL_SERVER_ERROR)
