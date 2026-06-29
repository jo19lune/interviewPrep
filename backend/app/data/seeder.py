"""Seeder pour remplir la base de données avec des exercices par défaut"""

import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.models.exercice import Exercice
from app.core.enums import Domaine, Niveau

logger = logging.getLogger(__name__)

EXERCICES_INITIALS = [
    {
        "titre": "QCM Algorithmique & Structures de Données",
        "description": "Évaluez vos compétences fondamentales en complexité algorithmique (Big O) et structures de données classiques.",
        "domaine": Domaine.TECHNIQUE.value,
        "difficulte": Niveau.INTERMEDIAIRE.value,
        "duree_sec": 600,
        "etiquettes": ["Algorithmes", "Complexité", "Structures de Données"],
        "questions": [
            {
                "type": "qcm",
                "enonce": "Quelle est la complexité temporelle dans le pire des cas pour la recherche d'un élément dans un Arbre Binaire de Recherche (BST) non équilibré ?",
                "options": ["O(1)", "O(log n)", "O(n)", "O(n log n)"],
                "reponse_correcte": 2,
                "explication": "Dans un BST non équilibré (dégénéré en liste chaînée), le pire des cas nécessite de parcourir tous les éléments, d'où une complexité de O(n)."
            },
            {
                "type": "qcm",
                "enonce": "Quel algorithme de tri garantit une complexité temporelle de O(n log n) dans tous les cas (pire, moyen, meilleur) ?",
                "options": ["Tri à bulles (Bubble Sort)", "Tri rapide (Quicksort)", "Tri par fusion (Merge Sort)", "Tri par insertion (Insertion Sort)"],
                "reponse_correcte": 2,
                "explication": "Le tri par fusion divise systématiquement la liste en deux et la fusionne, garantissant O(n log n) dans tous les cas."
            },
            {
                "type": "qcm",
                "enonce": "Quelle structure de données est couramment utilisée pour implémenter un parcours en largeur (BFS) dans un graphe ?",
                "options": ["Pile (Stack)", "File (Queue)", "Table de Hachage", "Arbre Binaire"],
                "reponse_correcte": 1,
                "explication": "Le parcours BFS explore niveau par niveau, ce qui nécessite une structure FIFO (First-In, First-Out), c'est-à-dire une File."
            }
        ]
    },
    {
        "titre": "Gestion de Conflits & Leadership",
        "description": "Entraînez-vous à répondre à des questions comportementales sur la résolution de conflits et le leadership d'équipe.",
        "domaine": Domaine.COMPORTEMENTAL.value,
        "difficulte": Niveau.AVANCE.value,
        "duree_sec": 900,
        "etiquettes": ["Management", "Communication", "STAR", "Conflits"],
        "questions": [
            {
                "type": "ouverte",
                "enonce": "Décrivez une situation où vous avez eu un désaccord professionnel majeur avec un collègue ou un manager. Comment l'avez-vous abordé et quel a été le résultat ?",
                "explication": "Utilisez la méthode STAR (Situation, Tâche, Action, Résultat). Montrez votre capacité d'écoute active, de négociation constructive et d'orientation vers les objectifs de l'entreprise."
            },
            {
                "type": "ouverte",
                "enonce": "Comment réagissez-vous si un membre clé de votre équipe sous-performe régulièrement et met en péril les livrables d'un projet critique ?",
                "explication": "Montrez un équilibre entre empathie humaine (comprendre les causes sous-jacentes) et rigueur professionnelle (mettre en place un plan de soutien et de suivi)."
            }
        ]
    },
    {
        "titre": "Conception d'Architecture Cloud Évolutive",
        "description": "Étude de cas complexe visant à concevoir un système hautement disponible et tolérant aux pannes.",
        "domaine": Domaine.ETUDE_DE_CAS.value,
        "difficulte": Niveau.EXPERT.value,
        "duree_sec": 1200,
        "etiquettes": ["Cloud", "System Design", "AWS", "Évolutivité"],
        "questions": [
            {
                "type": "ouverte",
                "enonce": "Vous devez concevoir l'architecture d'une plateforme e-commerce mondiale devant supporter un pic soudain de trafic (100x le trafic habituel) lors du Black Friday. Décrivez votre approche.",
                "explication": "Détaillez l'utilisation de Load Balancers, Auto Scaling, CDN pour le caching statique, bases de données répliquées en lecture, caches mémoire (Redis/Memcached) et mécanismes de découplage par files d'attente (SQS/Kafka)."
            }
        ]
    }
]

async def seed_exercises(db: AsyncSession):
    """Insérer les exercices par défaut si la table est vide"""
    try:
        # Vérifier si des exercices existent déjà
        result = await db.execute(select(Exercice).limit(1))
        exists = result.scalars().first()
        
        if exists:
            logger.info("Exercises already exist in database, skipping seeding")
            return
            
        logger.info("Seeding initial exercises into database...")
        for ex_data in EXERCICES_INITIALS:
            exercice = Exercice(
                titre=ex_data["titre"],
                description=ex_data["description"],
                domaine=ex_data["domaine"],
                difficulte=ex_data["difficulte"],
                duree_sec=ex_data["duree_sec"],
                etiquettes=ex_data["etiquettes"],
                questions=ex_data["questions"]
            )
            db.add(exercice)
            
        await db.commit()
        logger.info("Successfully seeded database with initial exercises")
    except Exception as e:
        await db.rollback()
        logger.error(f"Error seeding database: {e}")
        raise
