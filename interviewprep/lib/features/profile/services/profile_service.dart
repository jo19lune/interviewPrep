import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/auth_models.dart';
import 'dart:io';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  Future<UserResponse> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/profile/me');
      return UserResponse.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        throw Exception(ApiClient.errorMessage(e, 'Erreur lors du chargement du profil'));
      }
      throw Exception('Erreur inattendue');
    }
  }

  Future<UserResponse> updateProfile(UserProfileUpdate updateReq) async {
    try {
      final response = await _apiClient.dio.put('/profile/update', data: updateReq.toJson());
      return UserResponse.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        throw Exception(ApiClient.errorMessage(e, 'Erreur lors de la mise à jour'));
      }
      throw Exception('Erreur inattendue');
    }
  }

  Future<UserResponse> updateAvatar(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });
      final response = await _apiClient.dio.put('/profile/avatar', data: formData);
      return UserResponse.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        throw Exception(ApiClient.errorMessage(e, 'Erreur lors de la mise à jour de l\'avatar'));
      }
      throw Exception('Erreur inattendue');
    }
  }

  Future<void> changePassword(ChangePasswordRequest req) async {
    try {
      await _apiClient.dio.put('/profile/change-password', data: req.toJson());
    } catch (e) {
      if (e is DioException) {
        throw Exception(ApiClient.errorMessage(e, 'Erreur lors du changement de mot de passe'));
      }
      throw Exception('Erreur inattendue');
    }
  }
}
