import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'courriel': email,
          'mot_de_passe': password,
        },
      );
      
      final token = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];
      if (token != null) {
        await _apiClient.saveTokens(accessToken: token, refreshToken: refreshToken);
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? 'Erreur de connexion');
      }
      throw Exception('Erreur inattendue');
    }
  }

  Future<void> register(String fullName, String email, String password) async {
    try {
      // Pour fullName, on peut le séparer en prénom/nom ou passer tout dans 'prenom' si le backend le permet
      final parts = fullName.split(' ');
      final prenom = parts.isNotEmpty ? parts[0] : '';
      final nom = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'courriel': email,
          'mot_de_passe': password,
          'prenom': prenom,
          'nom': nom,
        },
      );
      
      final token = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];
      if (token != null) {
        await _apiClient.saveTokens(accessToken: token, refreshToken: refreshToken);
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? 'Erreur d\'inscription');
      }
      throw Exception('Erreur inattendue');
    }
  }

  Future<void> logout() async {
    await _apiClient.removeToken();
  }

  Future<void> deleteAccount() async {
    try {
      await _apiClient.dio.delete('/auth/me');
      await logout();
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erreur lors de la suppression du compte');
    } catch (e) {
      throw Exception('Erreur inattendue');
    }
  }
}
