import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:interviewprep/core/network/api_client.dart';
import 'package:interviewprep/features/profile/models/user_profile.dart';
import 'package:interviewprep/features/profile/services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  final apiClient = ApiClient(); // Assuming ApiClient is a singleton or can be instantiated like this
  return ProfileService(apiClient);
});

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile>>((ref) {
  return ProfileNotifier(ref.read(profileServiceProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile>> {
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
        prenom: prenom,
        nom: nom,
        domaine: domaine,
        niveau: niveau,
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
      final avatarUrl = await _profileService.uploadAvatar(
        bytes: bytes,
        path: path,
        filename: filename,
      );
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(avatarUrl: avatarUrl));
      }
    } catch (e) {
      rethrow;
    }
  }
}
