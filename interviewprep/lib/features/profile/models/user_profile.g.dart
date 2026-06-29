// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: json['id'] as String,
  courriel: json['courriel'] as String,
  prenom: json['prenom'] as String?,
  nom: json['nom'] as String?,
  domaine: json['domaine'] as String?,
  niveau: json['niveau'] as String?,
  estActif: json['est_actif'] as bool,
  avatarUrl: json['avatar_url'] as String?,
  creeLe: DateTime.parse(json['cree_le'] as String),
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'courriel': instance.courriel,
      'prenom': instance.prenom,
      'nom': instance.nom,
      'domaine': instance.domaine,
      'niveau': instance.niveau,
      'est_actif': instance.estActif,
      'avatar_url': instance.avatarUrl,
      'cree_le': instance.creeLe.toIso8601String(),
    };
