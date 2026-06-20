# ⚙️ InterviewPrep - Backend (FastAPI)

Ce répertoire contient le code source du backend de l'application **InterviewPrep**. Il est construit avec Python et le framework **FastAPI**.

## 🏗️ Architecture

Le backend suit une architecture modulaire pour séparer les préoccupations :

* **`app/main.py`** : Point d'entrée de l'application FastAPI.
* **`app/routers/`** : Définition des endpoints de l'API (authentification, dashboard, exercices, profil, simulation).
* **`app/services/`** : Logique métier et appels externes (IA, emails).
* **`app/models/`** : Modèles SQLAlchemy représentant les tables de la base de données.
* **`app/schemas/`** : Modèles Pydantic pour la validation des données d'entrée/sortie.
* **`app/core/`** : Configuration centrale, sécurité et utilitaires.
* **`app/data/`** : Gestion de la base de données et scripts de seed.

## 📋 Prérequis

* **Python** 3.9 ou supérieur
* **PostgreSQL** (ou SQLite pour le développement local rapide)
* **Docker** et **Docker Compose** (optionnel, mais recommandé)

## 🛠️ Installation et Configuration

1. **Créer un environnement virtuel**

   ```bash
   python -m venv venv
   ```

2. **Activer l'environnement virtuel**

   * Sous Linux/macOS : `source venv/bin/activate`
   * Sous Windows : `venv\Scripts\activate`

3. **Installer les dépendances**

   ```bash
   pip install -r requirements.txt
   ```

4. **Configuration des variables d'environnement**

   Copiez le fichier d'exemple et remplissez vos informations :

   ```bash
   cp .env.example .env
   ```

   Assurez-vous de configurer correctement les clés secrètes, l'URL de la base de données, et les éventuelles clés d'API externes (IA).

## 🚀 Lancer le Serveur

### Sans Docker (Développement local)

Assurez-vous que votre base de données est accessible et que `.env` est correctement configuré.

```bash
uvicorn app.main:app --reload
```

L'API sera accessible sur `http://127.0.0.1:8000`. Vous pouvez consulter la documentation interactive Swagger à l'adresse `http://127.0.0.1:8000/docs`.

### Avec Docker (Recommandé)

Si vous avez Docker installé, vous pouvez démarrer l'ensemble des services (base de données + backend) très facilement :

```bash
docker-compose up -d --build
```

## 🧪 Exécuter les Tests

Pour lancer la suite de tests automatisés (basée sur `pytest`) :

```bash
pytest
```
