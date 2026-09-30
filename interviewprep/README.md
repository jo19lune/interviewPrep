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
automatiquement les fichiers `.env` : `API_BASE_URL`, `BACKEND_API_KEY` et
`GOOGLE_CLIENT_ID` (connexion Google) doivent être injectées avec
`--dart-define`. `API_BASE_URL` est obligatoire et les routes sont
automatiquement préfixées par `/api/v1`.

La clé `BACKEND_API_KEY` est une clé d'application commune, pas un secret
utilisateur. Les routes privées continuent d'exiger le JWT.

Pour la connexion Google, `GOOGLE_CLIENT_ID` doit être le **Web client ID**
OAuth de l'application (celui que le backend vérifie via son propre
`GOOGLE_CLIENT_ID`). Le client ID Android n'est pas utilisé par le flux.

### Connexion Google Android : les deux causes d'échec

L'erreur caractéristique en développement est
`PlatformException(sign_in_failed, v0.d: 10)`, qui correspond à un
`DEVELOPER_ERROR` : l'application n'est pas enregistrée dans le projet Google
Cloud. Deux éléments sont nécessaires côté console.

1. **Le client OAuth Web.** Sous Android, `google_sign_in` reçoit
   `clientId` et `serverClientId`. Le plugin utilise `serverClientId` comme
   *audience* de l'`idToken`, et le backend vérifie cette audience. Il faut
   donc le client de type **Web**, pas celui de type Android.

2. **L'empreinte SHA-1 du keystore de signature.** Google Cloud Console →
   *Credentials* → votre client Android → *SHA-1 certificate fingerprints*.
   Comme `android/app/build.gradle.kts` signe la release avec la configuration
   `debug`, les empreintes à enregistrer pour le package
   `com.example.interviewprep` sont :

   ```text
   SHA-1:   82:06:01:BC:32:B7:68:18:71:66:61:C8:01:D7:6F:57:EF:F9:9E:1D
   SHA-256: B7:5A:5E:37:6B:0A:4B:A3:E2:D4:1F:5A:8D:51:B1:9E:9A:13:31:11:54:2E:C8:CF:F9:37:3E:33:71:49:03:A0
   ```

   Pour les régénérer après un changement de keystore :

   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey \
     -storepass android -keypass android
   ```

Le message affiché par l'application est volontairement actionnable plutôt que
le `v0.d: 10` brut, qui ne dit rien à l'utilisateur.

Pour utiliser le backend local :

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=BACKEND_API_KEY=...
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

### Affichage des erreurs du backend

`ApiClient.errorMessage` lit désormais le champ `detail` de la réponse **avant**
tout mapping générique par code HTTP. Le mapping par statut écrasait
précédemment des messages actionnables du backend : une génération IA
interrompue par quota s'affichait « Service indisponible » au lieu de la raison
réelle. Le code machine, lui, passe par l'en-tête `X-Error-Code`
(`ApiClient.errorCode`) — `SESSION_NOT_ACTIVE`, `SESSION_CANCELLED`,
`AI_QUOTA_EXCEEDED`, `STORAGE_UNAVAILABLE` — pour que l'interface puisse
réagir sans couplage au texte.

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
