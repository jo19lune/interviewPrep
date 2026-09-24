import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class UserRegisterRequest {
  final String courriel;
  @JsonKey(name: 'mot_de_passe')
  final String motDePasse;
  final String? prenom;
  final String? nom;

  UserRegisterRequest({
    required this.courriel,
    required this.motDePasse,
    this.prenom,
    this.nom,
  });

  factory UserRegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$UserRegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UserRegisterRequestToJson(this);
}

@JsonSerializable()
class UserLoginRequest {
  final String courriel;
  @JsonKey(name: 'mot_de_passe')
  final String motDePasse;

  UserLoginRequest({required this.courriel, required this.motDePasse});

  factory UserLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$UserLoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UserLoginRequestToJson(this);
}

@JsonSerializable()
class AuthResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  @JsonKey(name: 'token_type')
  final String tokenType;
  final UserResponse user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class UserResponse {
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
  final DateTime? creeLe;

  UserResponse({
    required this.id,
    required this.courriel,
    this.prenom,
    this.nom,
    this.domaine,
    this.niveau,
    required this.estActif,
    this.avatarUrl,
    this.creeLe,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserResponseToJson(this);
}

@JsonSerializable()
class UserProfileUpdate {
  final String? prenom;
  final String? nom;
  final String? domaine;
  final String? niveau;

  UserProfileUpdate({this.prenom, this.nom, this.domaine, this.niveau});

  factory UserProfileUpdate.fromJson(Map<String, dynamic> json) =>
      _$UserProfileUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileUpdateToJson(this);
}

@JsonSerializable()
class ChangePasswordRequest {
  @JsonKey(name: 'mot_de_passe_actuel')
  final String motDePasseActuel;
  @JsonKey(name: 'nouveau_mot_de_passe')
  final String nouveauMotDePasse;

  ChangePasswordRequest({
    required this.motDePasseActuel,
    required this.nouveauMotDePasse,
  });

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePasswordRequestToJson(this);
}

@JsonSerializable()
class ForgotPasswordRequest {
  final String courriel;

  ForgotPasswordRequest({required this.courriel});

  factory ForgotPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ForgotPasswordRequestToJson(this);
}

@JsonSerializable()
class VerifyResetCodeRequest {
  final String courriel;
  final String code;

  VerifyResetCodeRequest({required this.courriel, required this.code});

  factory VerifyResetCodeRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyResetCodeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$VerifyResetCodeRequestToJson(this);
}

@JsonSerializable()
class ResetPasswordRequest {
  final String courriel;
  final String code;
  @JsonKey(name: 'nouveau_mot_de_passe')
  final String nouveauMotDePasse;

  ResetPasswordRequest({
    required this.courriel,
    required this.code,
    required this.nouveauMotDePasse,
  });

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ResetPasswordRequestToJson(this);
}
