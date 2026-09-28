import 'package:dio/dio.dart';
import '../../../app/router/app_auth_guard.dart';
import '../../../core/network/api_client.dart';
import '../models/google_auth_models.dart';
import '../models/otp_models.dart';
import 'google_login_client.dart';

class GoogleAuthService {
  GoogleAuthService({ApiClient? apiClient, GoogleLoginClient? client})
    : _apiClient = apiClient ?? ApiClient(),
      _client = client ?? GoogleLoginClient();

  final ApiClient _apiClient;
  final GoogleLoginClient _client;

  Future<GoogleLoginResult> login() async {
    try {
      final idToken = await _client.signInAndGetIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Connexion Google annulée');
      }
      final response = await _apiClient.dio.post(
        '/auth/google',
        data: GoogleLoginRequest(idToken: idToken).toJson(),
      );
      final result = LoginResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      final auth = result.auth;
      if (auth != null) {
        await _apiClient.saveTokens(
          accessToken: auth.accessToken,
          refreshToken: auth.refreshToken,
        );
        authStateNotifier.setSession(hasSession: true, startupSettled: true);
      }
      return GoogleLoginResult(result: result);
    } on DioException catch (error) {
      throw Exception(
        ApiClient.errorMessage(error, 'Erreur de connexion Google'),
      );
    }
  }
}
