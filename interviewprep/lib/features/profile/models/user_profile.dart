import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String courriel,
    String? prenom,
    String? nom,
    String? domaine,
    String? niveau,
    @JsonKey(name: 'est_actif') required bool estActif,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'cree_le') required DateTime creeLe,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}
