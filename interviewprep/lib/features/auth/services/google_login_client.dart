import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/env.dart';

/// Client Google Sign-In qui retourne un **id_token Google brut** (audience =
/// le Web client ID) prêt à être échangé contre des jetons d'API sur
/// `POST /api/v1/auth/google`.
class GoogleLoginClient {
  GoogleSignIn? _googleSignIn;

  GoogleSignIn _signIn() {
    final clientId = Env.googleClientId;
    if (clientId.isEmpty) {
      throw StateError(
        'GOOGLE_CLIENT_ID doit être fournie avec '
        '--dart-define=GOOGLE_CLIENT_ID=...',
      );
    }
    return _googleSignIn ??= GoogleSignIn(
      // Web / iOS : OAuth client utilisé pour la connexion.
      clientId: clientId,
      // Android : le plugin interprète `serverClientId` comme l'audience du
      // token d'identification (le client ID Android n'est pas utilisé).
      serverClientId: clientId,
    );
  }

  Future<String?> signInAndGetIdToken() async {
    final account = await _signIn().signIn();
    if (account == null) {
      return null; // Connexion annulée par l'utilisateur.
    }
    final auth = await account.authentication;
    return auth.idToken;
  }
}