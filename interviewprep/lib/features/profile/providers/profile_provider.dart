import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:interviewprep/core/models/auth_models.dart';
import 'package:interviewprep/features/profile/services/profile_service.dart';
import 'dart:io';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserResponse>>((ref) {
  return ProfileNotifier(ref.read(profileServiceProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserResponse>> {
  final ProfileService _profileService;

  ProfileNotifier(this._profileService) : super(const AsyncValue.loading()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _profileService.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({
    String? prenom,
    String? nom,
    String? domaine,
    String? niveau,
  }) async {
    try {
      final updatedProfile = await _profileService.updateProfile(
        UserProfileUpdate(
          prenom: prenom,
          nom: nom,
          domaine: domaine,
          niveau: niveau,
        ),
      );
      state = AsyncValue.data(updatedProfile);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadAvatar({
    List<int>? bytes,
    String? path,
    required String filename,
  }) async {
    try {
      if (path == null) throw Exception('Chemin de fichier manquant');
      final updatedProfile = await _profileService.updateAvatar(File(path));
      state = AsyncValue.data(updatedProfile);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAvatar() async {
    try {
      final updatedProfile = await _profileService.deleteAvatar();
      state = AsyncValue.data(updatedProfile);
    } catch (e) {
      rethrow;
    }
  }
}
