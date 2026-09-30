import 'package:flutter/services.dart';
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
      // token d'identification. **Ce doit être le client OAuth Web**, jamais
      // le client Android : le backend vérifie l'audience contre
      // GOOGLE_CLIENT_ID et refuserait l'idToken.
      serverClientId: clientId,
    );
  }

  Future<String?> signInAndGetIdToken() async {
    try {
      final account = await _signIn().signIn();
      if (account == null) {
        return null; // Connexion annulée par l'utilisateur.
      }
      final auth = await account.authentication;
      return auth.idToken;
    } on PlatformException catch (e) {
      // `sign_in_failed` / code 10 = DEVELOPER_ERROR : le nom de package ou
      // l'empreinte SHA-1 n'est pas enregistré dans le projet Google Cloud.
      // Le message brut (`v0.d: 10`) n'est pas actionnable pour l'utilisateur.
      throw Exception(_messageForPlatformException(e));
    }
  }

  String _messageForPlatformException(PlatformException e) {
    if (e.code == 'sign_in_failed' || e.code == 'ERROR_INVALID_CREDENTIAL') {
      return 'Connexion Google refusee. Verifiez que le nom de package et '
          "l'empreinte SHA-1 de l'application sont enregistres dans la "
          'console Google Cloud, et que GOOGLE_CLIENT_ID correspond au client '
          'OAuth Web.';
    }
    return 'Connexion Google impossible (${e.code}). Reessayez dans un instant.';
  }
}
