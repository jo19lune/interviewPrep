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

Copiez `interviewprep/.env.example` comme référence. Flutter ne charge pas
automatiquement les fichiers `.env` : `API_BASE_URL` et `BACKEND_API_KEY`
doivent être injectées avec `--dart-define`. `API_BASE_URL` est obligatoire et
les routes sont automatiquement préfixées par `/api/v1`.

La clé `BACKEND_API_KEY` est une clé d'application commune, pas un secret
utilisateur. Les routes privées continuent d'exiger le JWT.

Pour utiliser le backend local :

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:9000 --dart-define=BACKEND_API_KEY=...
```

Sous PowerShell, utilisez les scripts fournis :

```powershell
$env:BACKEND_API_KEY = "votre-cle"
.\tool\run_dev.ps1
.\tool\build_prod.ps1
```

Ne commitez jamais cette valeur dans un script ou un fichier de configuration.
Si une clé a déjà été exposée dans l'historique ou dans un terminal partagé,
révoquez-la et générez-en une nouvelle côté backend.

## 🚀 Lancer l'Application

L'application exige une URL API injectée au lancement ou au build.

Pour lancer l'application sur un appareil connecté ou un émulateur :

```bash
# Pour voir les appareils disponibles
flutter devices

# Pour lancer avec l'API Render
flutter run --dart-define=API_BASE_URL=https://interviewprep-api-7lnr.onrender.com --dart-define=BACKEND_API_KEY=...

# Pour spécifier un appareil (ex: Chrome pour le web)
flutter run -d chrome
```

## 📚 Ressources Flutter

Si vous débutez avec Flutter, voici quelques ressources utiles :

* [Laboratoire de code : Écrire votre première application Flutter](https://docs.flutter.dev/get-started/codelab)
* [Documentation officielle de Flutter](https://docs.flutter.dev/)
