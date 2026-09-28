import '../../../core/models/auth_models.dart';
import 'otp_models.dart';

class GoogleLoginRequest {
  const GoogleLoginRequest({required this.idToken});

  final String idToken;

  Map<String, dynamic> toJson() => {'id_token': idToken};
}

class GoogleLoginResult {
  const GoogleLoginResult({required this.result});

  /// Réponse du backend. Quando [LoginResult.requiresTwoFactor] est vrai,
  /// [LoginResult.auth] est null : aucun jeton n'est délivré avant validation
  /// du code OTP.
  final LoginResult result;

  bool get requiresTwoFactor => result.requiresTwoFactor;

  int? get challengeExpiresInSeconds => result.challengeExpiresInSeconds;

  AuthResponse? get auth => result.auth;
}
