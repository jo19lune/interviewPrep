import '../../../core/models/auth_models.dart';

class GoogleLoginRequest {
  const GoogleLoginRequest({required this.idToken});

  final String idToken;

  Map<String, dynamic> toJson() => {'id_token': idToken};
}

class GoogleLoginResult {
  const GoogleLoginResult({required this.auth});

  final AuthResponse auth;
}
