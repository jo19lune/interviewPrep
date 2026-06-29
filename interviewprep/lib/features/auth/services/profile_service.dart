import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/user.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  Future<User> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/profile/me');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        ApiClient.errorMessage(e, 'Erreur lors du chargement du profil'),
      );
    }
  }

  Future<User> updateProfile(UserProfileUpdateRequest request) async {
    try {
      final response = await _apiClient.dio.put(
        '/profile/update',
        data: request.toJson(),
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        ApiClient.errorMessage(e, 'Erreur lors de la mise à jour du profil'),
      );
    }
  }

  Future<AvatarUploadResponse> uploadAvatar(File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.put(
        '/profile/avatar',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.data is Map<String, dynamic>) {
        return AvatarUploadResponse.fromJson(response.data);
      }
      return AvatarUploadResponse(
        avatarUrl: response.data['avatar_url'] ?? response.data['avatarUrl'] ?? '',
        message: response.data['message'] ?? 'Avatar mis à jour',
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.errorMessage(e, 'Erreur lors du téléchargement de l\'avatar'),
      );
    }
  }
}
