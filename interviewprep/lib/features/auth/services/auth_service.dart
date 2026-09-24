import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/auth_models.dart';
import '../models/otp_models.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<LoginResult> login(String email, String password) async {
    try {
      final req = UserLoginRequest(courriel: email, motDePasse: password);
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: req.toJson(),
      );

      final result = LoginResult.fromJson(response.data);
      if (result.auth != null) {
        await _apiClient.saveTokens(
          accessToken: result.auth!.accessToken,
          refreshToken: result.auth!.refreshToken,
        );
      }
      return result;
    } catch (e) {
      if (e is DioException) {
        throw Exception(ApiClient.errorMessage(e, 'Erreur de connexion'));
      }
      throw Exception('Erreur inattendue');
    }
  }

  Future<AuthResponse> register(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      final parts = fullName.split(' ');
      final prenom = parts.isNotEmpty ? parts[0] : '';
      final nom = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final req = UserRegisterRequest(
        courriel: email,
        motDePasse: password,
        prenom: prenom,
        nom: nom,
      );
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: req.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _apiClient.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );
      return authResponse;
    } catch (e) {
      if (e is DioException) {
        throw Exception(ApiClient.errorMessage(e, 'Erreur d\'inscription'));
      }
      throw Exception('Erreur inattendue');
    }
  }

  Future<AuthResponse> refresh() async {
    try {
      final response = await _apiClient.dio.post('/auth/refresh');
      final authResponse = AuthResponse.fromJson(response.data);
      await _apiClient.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );
      return authResponse;
    } catch (e) {
      throw Exception('Erreur de rafraichissement');
    }
  }

  Future<UserResponse> getMe() async {
    final response = await _apiClient.dio.get('/auth/me');
    return UserResponse.fromJson(response.data);
  }

  Future<void> logout() async {
    try {
      // Révocation distante best-effort : le backend ajoute le token à la
      // blocklist. On supprime toujours les jetons locaux, même si le
      // backend est injoignable ou si le token est déjà expiré.
      await _apiClient.dio.post('/auth/logout');
    } catch (_) {
      // Ignoré : la déconnexion locale doit toujours aboutir.
    }
    await _apiClient.removeToken();
  }

  Future<void> deleteAccount() async {
    try {
      await _apiClient.dio.delete('/auth/me');
      await logout();
    } on DioException catch (e) {
      throw Exception(
        ApiClient.errorMessage(e, 'Erreur lors de la suppression du compte'),
      );
    } catch (e) {
      throw Exception('Erreur inattendue');
    }
  }

  Future<void> forgotPassword(String email) async {
    final req = ForgotPasswordRequest(courriel: email);
    await _apiClient.dio.post('/auth/forgot-password', data: req.toJson());
  }

  Future<void> verifyResetCode(String email, String code) async {
    final req = VerifyResetCodeRequest(courriel: email, code: code);
    await _apiClient.dio.post('/auth/verify-reset-code', data: req.toJson());
  }

  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final req = ResetPasswordRequest(
      courriel: email,
      code: code,
      nouveauMotDePasse: newPassword,
    );
    await _apiClient.dio.post('/auth/reset-password', data: req.toJson());
  }
}
