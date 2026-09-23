import '../../../core/models/auth_models.dart';

class LoginResult {
  const LoginResult({
    this.auth,
    this.requiresTwoFactor = false,
    this.challengeExpiresInSeconds,
    this.user,
  });

  final AuthResponse? auth;
  final bool requiresTwoFactor;
  final int? challengeExpiresInSeconds;
  final UserResponse? user;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final accessToken = json['access_token'] as String?;
    final refreshToken = json['refresh_token'] as String?;
    final userJson = json['user'];
    final user = userJson is Map<String, dynamic>
        ? UserResponse.fromJson(userJson)
        : null;
    final hasTokens =
        accessToken != null && refreshToken != null && user != null;
    return LoginResult(
      auth: hasTokens
          ? AuthResponse(
              accessToken: accessToken,
              refreshToken: refreshToken,
              tokenType: json['token_type'] as String? ?? 'bearer',
              user: user,
            )
          : null,
      requiresTwoFactor: json['requires_2fa'] as bool? ?? false,
      challengeExpiresInSeconds: json['challenge_expires_in_seconds'] as int?,
      user: user,
    );
  }
}

class LoginOtpRequest {
  const LoginOtpRequest({required this.email, required this.code});

  final String email;
  final String code;

  Map<String, dynamic> toJson() => {'courriel': email, 'code': code};
}
