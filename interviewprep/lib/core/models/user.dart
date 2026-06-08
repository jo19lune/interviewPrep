class User {
  final String id;
  final String courriel;
  final String? prenom;
  final String? nom;
  final String? domaine;
  final String? niveau;
  final bool estActif;
  final DateTime creeLe;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.courriel,
    this.prenom,
    this.nom,
    this.domaine,
    this.niveau,
    required this.estActif,
    required this.creeLe,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    courriel: json['courriel'] as String,
    prenom: json['prenom'] as String?,
    nom: json['nom'] as String?,
    domaine: json['domaine'] as String?,
    niveau: json['niveau'] as String?,
    estActif: json['est_actif'] as bool? ?? true,
    creeLe: DateTime.parse((json['cree_le'] as String?) ?? json['creeLe'] as String),
    avatarUrl: json['avatar_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'courriel': courriel,
    'prenom': prenom,
    'nom': nom,
    'domaine': domaine,
    'niveau': niveau,
    'est_actif': estActif,
    'cree_le': creeLe.toIso8601String(),
    'avatar_url': avatarUrl,
  };

  String get fullName => [prenom, nom].where((s) => s != null && s.isNotEmpty).join(' ');

  String get initials {
    final name = fullName.trim();
    if (name.isEmpty) return courriel[0].toUpperCase();
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

class UserProfileUpdateRequest {
  final String? prenom;
  final String? nom;
  final String? domaine;
  final String? niveau;

  const UserProfileUpdateRequest({
    this.prenom,
    this.nom,
    this.domaine,
    this.niveau,
  });

  factory UserProfileUpdateRequest.fromJson(Map<String, dynamic> json) =>
      UserProfileUpdateRequest(
        prenom: json['prenom'] as String?,
        nom: json['nom'] as String?,
        domaine: json['domaine'] as String?,
        niveau: json['niveau'] as String?,
      );

  Map<String, dynamic> toJson() => {
    if (prenom != null) 'prenom': prenom,
    if (nom != null) 'nom': nom,
    if (domaine != null) 'domaine': domaine,
    if (niveau != null) 'niveau': niveau,
  };
}

class AvatarUploadResponse {
  final String avatarUrl;
  final String message;

  const AvatarUploadResponse({
    required this.avatarUrl,
    required this.message,
  });

  factory AvatarUploadResponse.fromJson(Map<String, dynamic> json) =>
      AvatarUploadResponse(
        avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'avatar_url': avatarUrl,
    'message': message,
  };
}

class Domaine {
  final String value;
  const Domaine._(this.value);

  static const technique = Domaine._('TECHNIQUE');
  static const comportemental = Domaine._('COMPORTEMENTAL');
  static const situationnel = Domaine._('SITUATIONNEL');
  static const etudeDeCas = Domaine._('ETUDE_DE_CAS');
  static const motivation = Domaine._('MOTIVATION');

  static const values = [
    technique,
    comportemental,
    situationnel,
    etudeDeCas,
    motivation,
  ];

  @override
  String toString() => value;
}

class Niveau {
  final String value;
  const Niveau._(this.value);

  static const debutant = Niveau._('DEBUTANT');
  static const intermediaire = Niveau._('INTERMEDIAIRE');
  static const avance = Niveau._('AVANCE');
  static const expert = Niveau._('EXPERT');

  static const values = [debutant, intermediaire, avance, expert];

  @override
  String toString() => value;
}
