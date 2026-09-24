import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class ForgotPasswordService {
  final ApiClient _apiClient = ApiClient();

  Future<void> requestResetCode(String email) async {
    try {
      await _apiClient.dio.post(
        '/auth/forgot-password',
        data: {'courriel': email},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw Exception(
          'Trop de tentatives. Veuillez réessayer dans quelques minutes.',
        );
      }
      throw Exception(
        ApiClient.errorMessage(
          e,
          'Erreur lors de la demande de réinitialisation',
        ),
      );
    }
  }

  Future<bool> verifyResetCode(String email, String code) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/verify-reset-code',
        data: {'courriel': email, 'code': code},
      );
      return response.data['valid'] == true;
    } on DioException catch (e) {
      throw Exception(ApiClient.errorMessage(e, 'Code invalide ou expiré'));
    }
  }

  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      await _apiClient.dio.post(
        '/auth/reset-password',
        data: {
          'courriel': email,
          'code': code,
          'nouveau_mot_de_passe': newPassword,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.errorMessage(
          e,
          'Erreur lors de la réinitialisation du mot de passe',
        ),
      );
    }
  }
}
