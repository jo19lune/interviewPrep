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
      throw Exception(e.response?.data['detail'] ?? 'Erreur lors de la récupération du profil');
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
          if (prenom != null) 'prenom': prenom,
          if (nom != null) 'nom': nom,
          if (domaine != null) 'domaine': domaine,
          if (niveau != null) 'niveau': niveau,
        },
      );
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erreur lors de la mise à jour du profil');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiClient.dio.put(
        '/profile/change-password',
        data: {
          'mot_de_passe_actuel': currentPassword,
          'nouveau_mot_de_passe': newPassword,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erreur lors du changement de mot de passe');
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Not strictly an API call to change avatar directly via URL in backend yet, 
  // wait, the backend has an upload avatar, but the maquette uses a string URL for input. 
  // Let's stick to updateProfile if avatar is updated via another mechanism or we can simulate it 
  // as per backend: upload_avatar takes a File.
}
