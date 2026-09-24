import 'package:dio/dio.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/network/api_client.dart';
import '../models/otp_models.dart';

class OtpService {
  OtpService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AuthResponse> verifyLoginCode(String email, String code) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login/verify-otp',
        data: LoginOtpRequest(email: email, code: code).toJson(),
      );
      final auth = AuthResponse.fromJson(response.data);
      await _apiClient.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );
      return auth;
    } on DioException catch (error) {
      throw Exception(ApiClient.errorMessage(error, 'Code invalide ou expiré'));
    }
  }
}
