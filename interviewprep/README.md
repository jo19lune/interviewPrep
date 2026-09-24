# 📱 InterviewPrep - Frontend (Flutter)

Ce répertoire contient le code source de l'application cliente **InterviewPrep**. Elle est développée avec le framework **Flutter**, permettant de cibler les plateformes iOS, Android, et Web à partir d'un seul code base.

## 🏗️ Structure du Projet

L'application est structurée par fonctionnalités (Feature-First Architecture) dans le dossier `lib/` :

* **`app/`** : Bootstrap de l'application, configuration du routeur et thème partagé.
* **`features/`** : Contient les différentes sections de l'application (auth, dashboard, exercises, profile, simulation, qa).
  * Chaque feature possède ses propres dossiers : `screens/` (vues), `providers/` (gestion d'état), `services/` (logique et appels API), et `models/`.
* **`features/qa/`** : Feature du système de questions/réponses.
* **`assets/`** : Images, icônes et polices (ex: `mon_logo.png`).
* **`main.dart`** : Point d'entrée minimal de l'application Flutter.

## 📋 Prérequis

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (version stable recommandée)
* Android Studio / Xcode (pour la compilation mobile)
* Un appareil physique ou un émulateur configuré

## 🛠️ Configuration

1. Assurez-vous que votre environnement Flutter est correctement installé en lançant :

   ```bash
   flutter doctor
   ```

2. Dans le dossier `interviewprep/`, téléchargez les dépendances du projet :

   ```bash
   flutter pub get
   ```

3. Si vous avez modifié des modèles nécessitant de la génération de code (comme avec `json_serializable`), exécutez :

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

## Configuration production

Copiez `interviewprep/.env.example` comme référence et utilisez les mêmes
valeurs `API_BASE_URL` et `BACKEND_API_KEY` pour Android et iOS. Flutter ne
charge pas automatiquement ce fichier : injectez les valeurs avec
`--dart-define`.

La clé `BACKEND_API_KEY` est une clé d'application commune, pas un secret
utilisateur. Les routes privées continuent d'exiger le JWT.

## 🚀 Lancer l'Application

Assurez-vous que le **Backend FastAPI** est en cours d'exécution si l'application doit communiquer avec l'API.

Pour lancer l'application sur un appareil connecté ou un émulateur :

```bash
# Pour voir les appareils disponibles
flutter devices

# Pour lancer sur l'appareil par défaut
flutter run

# Pour spécifier un appareil (ex: Chrome pour le web)
flutter run -d chrome
```

## 📚 Ressources Flutter

Si vous débutez avec Flutter, voici quelques ressources utiles :

* [Laboratoire de code : Écrire votre première application Flutter](https://docs.flutter.dev/get-started/codelab)
* [Documentation officielle de Flutter](https://docs.flutter.dev/)
