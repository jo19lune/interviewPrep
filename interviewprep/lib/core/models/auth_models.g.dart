// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRegisterRequest _$UserRegisterRequestFromJson(Map<String, dynamic> json) =>
    UserRegisterRequest(
      courriel: json['courriel'] as String,
      motDePasse: json['mot_de_passe'] as String,
      prenom: json['prenom'] as String?,
      nom: json['nom'] as String?,
    );

Map<String, dynamic> _$UserRegisterRequestToJson(
  UserRegisterRequest instance,
) => <String, dynamic>{
  'courriel': instance.courriel,
  'mot_de_passe': instance.motDePasse,
  'prenom': instance.prenom,
  'nom': instance.nom,
};

UserLoginRequest _$UserLoginRequestFromJson(Map<String, dynamic> json) =>
    UserLoginRequest(
      courriel: json['courriel'] as String,
      motDePasse: json['mot_de_passe'] as String,
    );

Map<String, dynamic> _$UserLoginRequestToJson(UserLoginRequest instance) =>
    <String, dynamic>{
      'courriel': instance.courriel,
      'mot_de_passe': instance.motDePasse,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  tokenType: json['token_type'] as String,
  user: UserResponse.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'token_type': instance.tokenType,
      'user': instance.user,
    };

UserResponse _$UserResponseFromJson(Map<String, dynamic> json) => UserResponse(
  id: json['id'] as String,
  courriel: json['courriel'] as String,
  prenom: json['prenom'] as String?,
  nom: json['nom'] as String?,
  domaine: json['domaine'] as String?,
  niveau: json['niveau'] as String?,
  estActif: json['est_actif'] as bool,
  avatarUrl: json['avatar_url'] as String?,
  creeLe: json['cree_le'] == null
      ? null
      : DateTime.parse(json['cree_le'] as String),
);

Map<String, dynamic> _$UserResponseToJson(UserResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'courriel': instance.courriel,
      'prenom': instance.prenom,
      'nom': instance.nom,
      'domaine': instance.domaine,
      'niveau': instance.niveau,
      'est_actif': instance.estActif,
      'avatar_url': instance.avatarUrl,
      'cree_le': instance.creeLe?.toIso8601String(),
    };

UserProfileUpdate _$UserProfileUpdateFromJson(Map<String, dynamic> json) =>
    UserProfileUpdate(
      prenom: json['prenom'] as String?,
      nom: json['nom'] as String?,
      domaine: json['domaine'] as String?,
      niveau: json['niveau'] as String?,
    );

Map<String, dynamic> _$UserProfileUpdateToJson(UserProfileUpdate instance) =>
    <String, dynamic>{
      'prenom': instance.prenom,
      'nom': instance.nom,
      'domaine': instance.domaine,
      'niveau': instance.niveau,
    };

ChangePasswordRequest _$ChangePasswordRequestFromJson(
  Map<String, dynamic> json,
) => ChangePasswordRequest(
  motDePasseActuel: json['mot_de_passe_actuel'] as String,
  nouveauMotDePasse: json['nouveau_mot_de_passe'] as String,
);

Map<String, dynamic> _$ChangePasswordRequestToJson(
  ChangePasswordRequest instance,
) => <String, dynamic>{
  'mot_de_passe_actuel': instance.motDePasseActuel,
  'nouveau_mot_de_passe': instance.nouveauMotDePasse,
};

ForgotPasswordRequest _$ForgotPasswordRequestFromJson(
  Map<String, dynamic> json,
) => ForgotPasswordRequest(courriel: json['courriel'] as String);

Map<String, dynamic> _$ForgotPasswordRequestToJson(
  ForgotPasswordRequest instance,
) => <String, dynamic>{'courriel': instance.courriel};

VerifyResetCodeRequest _$VerifyResetCodeRequestFromJson(
  Map<String, dynamic> json,
) => VerifyResetCodeRequest(
  courriel: json['courriel'] as String,
  code: json['code'] as String,
);

Map<String, dynamic> _$VerifyResetCodeRequestToJson(
  VerifyResetCodeRequest instance,
) => <String, dynamic>{'courriel': instance.courriel, 'code': instance.code};

ResetPasswordRequest _$ResetPasswordRequestFromJson(
  Map<String, dynamic> json,
) => ResetPasswordRequest(
  courriel: json['courriel'] as String,
  code: json['code'] as String,
  nouveauMotDePasse: json['nouveau_mot_de_passe'] as String,
);

Map<String, dynamic> _$ResetPasswordRequestToJson(
  ResetPasswordRequest instance,
) => <String, dynamic>{
  'courriel': instance.courriel,
  'code': instance.code,
  'nouveau_mot_de_passe': instance.nouveauMotDePasse,
};
