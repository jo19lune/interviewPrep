import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewprep/features/profile/services/profile_service.dart';
import 'package:interviewprep/features/profile/models/user_profile.dart';
import 'package:interviewprep/core/models/auth_models.dart';
import 'dart:io';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final profileProvider =
    NotifierProvider<ProfileNotifier, AsyncValue<UserProfile>>(() {
      return ProfileNotifier();
    });

class ProfileNotifier extends Notifier<AsyncValue<UserProfile>> {
  late final ProfileService _profileService;

  @override
  AsyncValue<UserProfile> build() {
    _profileService = ref.watch(profileServiceProvider);
    fetchProfile();
    return const AsyncValue.loading();
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
      UserProfile updatedProfile;
      if (path != null) {
        updatedProfile = await _profileService.updateAvatar(File(path));
      } else if (bytes != null) {
        updatedProfile = await _profileService.updateAvatarBytes(
          bytes,
          filename,
        );
      } else {
        throw Exception('Aucune donnée d\'avatar fournie');
      }
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
