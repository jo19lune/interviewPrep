# 🎯 InterviewPrep

Bienvenue dans le dépôt principal du projet **InterviewPrep**. Cette application a pour but d'aider les candidats à se préparer aux entretiens d'embauche grâce à des simulations interactives et des exercices ciblés.

## 🏗️ Architecture du Projet

Le projet est divisé en deux parties principales :

* **Backend** (`/backend`) : Une API robuste développée en Python avec le framework **FastAPI**. Il gère la logique métier, la base de données, l'authentification et les intégrations avec l'intelligence artificielle pour les simulations d'entretiens.
* **Frontend** (`/interviewprep`) : Une application mobile et web interactive développée avec **Flutter** (Dart). Elle offre une interface utilisateur fluide pour accéder aux exercices, suivre sa progression et réaliser des simulations.

## 🚀 Objectifs de l'Application

* **Simulations Réalistes** : Offrir des environnements de simulation d'entretiens alimentés par l'IA.
* **Exercices Pratiques** : Proposer une bibliothèque d'exercices techniques et comportementaux.
* **Suivi de Progression** : Permettre aux utilisateurs de visualiser leurs statistiques, points forts et axes d'amélioration.
* **Accessibilité** : Être disponible sur de multiples plateformes (Mobile, Web, Desktop) grâce à Flutter.

## 🏁 Démarrage Rapide

Pour lancer le projet complet en environnement de développement, vous devrez exécuter à la fois le backend et le frontend.

### 1. Démarrer le Backend

Veuillez vous référer au fichier [backend/README.md](./backend/README.md) pour les instructions détaillées concernant la configuration de l'environnement Python, la base de données et le lancement du serveur FastAPI.

En bref :

```bash
cd backend
python -m venv venv
source venv/bin/activate  # ou venv\Scripts\activate sous Windows
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### 2. Démarrer le Frontend

Consultez le fichier [interviewprep/README.md](./interviewprep/README.md) pour configurer votre environnement Flutter et lancer l'application.

En bref :

```bash
cd interviewprep
flutter pub get
flutter run
```

## 🤝 Contribution

Si vous souhaitez contribuer au projet, assurez-vous de respecter les standards de code en place dans chaque partie (PEP 8 pour Python, standards Dart pour Flutter) et de documenter vos modifications.
