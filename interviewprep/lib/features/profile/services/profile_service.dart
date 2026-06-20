import 'package:dio/dio.dart';
import 'package:interviewprep/core/network/api_client.dart';
import 'package:interviewprep/features/profile/models/user_profile.dart';

class ProfileService {
  final ApiClient _apiClient;

  ProfileService(this._apiClient);

  Future<UserProfile> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/profile/me');
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['detail'] ??
            'Erreur lors de la récupération du profil',
      );
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<UserProfile> updateProfile({
    String? prenom,
    String? nom,
    String? domaine,
    String? niveau,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/profile/update',
        data: {
          ...?prenom != null ? {'prenom': prenom} : null,
          ...?nom != null ? {'nom': nom} : null,
          ...?domaine != null ? {'domaine': domaine} : null,
          ...?niveau != null ? {'niveau': niveau} : null,
        },
      );
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['detail'] ?? 'Erreur lors de la mise à jour du profil',
      );
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _apiClient.dio.put(
        '/profile/change-password',
        data: {
          'mot_de_passe_actuel': currentPassword,
          'nouveau_mot_de_passe': newPassword,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['detail'] ??
            'Erreur lors du changement de mot de passe',
      );
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<String> uploadAvatar({
    List<int>? bytes,
    String? path,
    required String filename,
  }) async {
    try {
      final formData = FormData();
      if (path != null) {
        formData.files.add(
          MapEntry(
            'file',
            await MultipartFile.fromFile(path, filename: filename),
          ),
        );
      } else if (bytes != null) {
        formData.files.add(
          MapEntry('file', MultipartFile.fromBytes(bytes, filename: filename)),
        );
      } else {
        throw Exception('Aucun fichier fourni');
      }

      final response = await _apiClient.dio.put(
        '/profile/avatar',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data['avatar_url'] as String;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['detail'] ??
            'Erreur lors du téléchargement de l\'avatar',
      );
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }
}
