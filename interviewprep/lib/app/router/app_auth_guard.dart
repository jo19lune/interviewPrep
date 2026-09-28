import 'package:flutter/widgets.dart';
import 'app_routes.dart';

/// Notifie le routeur des changements de session pour que le guard de
/// navigation puisse arbitrer les routes privées en temps réel.
class AuthStateNotifier extends ChangeNotifier {
  bool _hasSession = false;

  /// `true` une fois que la vérification de session au démarrage a rendu son
  /// verdict. Tant que ce n'est pas le cas, aucune redirection n'est appliquée
  /// afin de ne pas éjecter l'utilisateur vers /login alors qu'un jeton valide
  /// est en cours de validation.
  bool _startupSettled = false;

  bool get hasSession => _hasSession;

  bool get startupSettled => _startupSettled;

  void setSession({required bool hasSession, required bool startupSettled}) {
    if (_hasSession == hasSession && _startupSettled == startupSettled) {
      return;
    }
    _hasSession = hasSession;
    _startupSettled = startupSettled;
    notifyListeners();
  }
}

/// Instance unique partagée entre le routeur et la vérification de démarrage.
final AuthStateNotifier authStateNotifier = AuthStateNotifier();

/// Routes accessibles sans session : connexion, inscription et récupération
/// de mot de passe (y compris la validation OTP associée).
const Set<String> publicPaths = {
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
  AppRoutes.resetPassword,
  AppRoutes.verifyOtp,
};

/// Guard de navigation : empêche l'affichage des écrans authentifiés tant
/// qu'aucune session valide n'est établie, et redirige un utilisateur déjà
/// connecté qui tente d'atteindre une route publique.
String? resolveAuthRedirect(AuthStateNotifier notifier, String path) {
  if (!notifier.startupSettled) return null;
  if (notifier.hasSession) {
    return publicPaths.contains(path) ? AppRoutes.dashboard : null;
  }
  return publicPaths.contains(path) ? null : AppRoutes.login;
}
