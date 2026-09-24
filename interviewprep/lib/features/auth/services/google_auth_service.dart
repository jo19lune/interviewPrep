import 'package:dio/dio.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/network/api_client.dart';
import '../models/google_auth_models.dart';
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
      final auth = AuthResponse.fromJson(response.data);
      await _apiClient.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );
      return GoogleLoginResult(auth: auth);
    } on DioException catch (error) {
      throw Exception(
        ApiClient.errorMessage(error, 'Erreur de connexion Google'),
      );
    }
  }
}
