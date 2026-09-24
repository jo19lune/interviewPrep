import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String courriel;
  final String? prenom;
  final String? nom;
  final String? domaine;
  final String? niveau;
  @JsonKey(name: 'est_actif')
  final bool estActif;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'cree_le')
  final DateTime creeLe;

  const UserProfile({
    required this.id,
    required this.courriel,
    this.prenom,
    this.nom,
    this.domaine,
    this.niveau,
    required this.estActif,
    this.avatarUrl,
    required this.creeLe,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? id,
    String? courriel,
    String? prenom,
    String? nom,
    String? domaine,
    String? niveau,
    bool? estActif,
    String? avatarUrl,
    DateTime? creeLe,
  }) {
    return UserProfile(
      id: id ?? this.id,
      courriel: courriel ?? this.courriel,
      prenom: prenom ?? this.prenom,
      nom: nom ?? this.nom,
      domaine: domaine ?? this.domaine,
      niveau: niveau ?? this.niveau,
      estActif: estActif ?? this.estActif,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      creeLe: creeLe ?? this.creeLe,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.courriel == courriel &&
        other.prenom == prenom &&
        other.nom == nom &&
        other.domaine == domaine &&
        other.niveau == niveau &&
        other.estActif == estActif &&
        other.avatarUrl == avatarUrl &&
        other.creeLe == creeLe;
  }

  @override
  int get hashCode => Object.hash(
    id,
    courriel,
    prenom,
    nom,
    domaine,
    niveau,
    estActif,
    avatarUrl,
    creeLe,
  );

  @override
  String toString() =>
      'UserProfile(id: $id, courriel: $courriel, prenom: $prenom, '
      'nom: $nom, domaine: $domaine, niveau: $niveau, estActif: $estActif, '
      'avatarUrl: $avatarUrl, creeLe: $creeLe)';
}
