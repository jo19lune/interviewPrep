// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfile {

 String get id; String get courriel; String? get prenom; String? get nom; String? get domaine; String? get niveau;@JsonKey(name: 'est_actif') bool get estActif;@JsonKey(name: 'avatar_url') String? get avatarUrl;@JsonKey(name: 'cree_le') DateTime get creeLe;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.courriel, courriel) || other.courriel == courriel)&&(identical(other.prenom, prenom) || other.prenom == prenom)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.domaine, domaine) || other.domaine == domaine)&&(identical(other.niveau, niveau) || other.niveau == niveau)&&(identical(other.estActif, estActif) || other.estActif == estActif)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.creeLe, creeLe) || other.creeLe == creeLe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courriel,prenom,nom,domaine,niveau,estActif,avatarUrl,creeLe);

@override
String toString() {
  return 'UserProfile(id: $id, courriel: $courriel, prenom: $prenom, nom: $nom, domaine: $domaine, niveau: $niveau, estActif: $estActif, avatarUrl: $avatarUrl, creeLe: $creeLe)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 String id, String courriel, String? prenom, String? nom, String? domaine, String? niveau,@JsonKey(name: 'est_actif') bool estActif,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'cree_le') DateTime creeLe
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? courriel = null,Object? prenom = freezed,Object? nom = freezed,Object? domaine = freezed,Object? niveau = freezed,Object? estActif = null,Object? avatarUrl = freezed,Object? creeLe = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courriel: null == courriel ? _self.courriel : courriel // ignore: cast_nullable_to_non_nullable
as String,prenom: freezed == prenom ? _self.prenom : prenom // ignore: cast_nullable_to_non_nullable
as String?,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,domaine: freezed == domaine ? _self.domaine : domaine // ignore: cast_nullable_to_non_nullable
as String?,niveau: freezed == niveau ? _self.niveau : niveau // ignore: cast_nullable_to_non_nullable
as String?,estActif: null == estActif ? _self.estActif : estActif // ignore: cast_nullable_to_non_nullable
as bool,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,creeLe: null == creeLe ? _self.creeLe : creeLe // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String courriel,  String? prenom,  String? nom,  String? domaine,  String? niveau, @JsonKey(name: 'est_actif')  bool estActif, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'cree_le')  DateTime creeLe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.courriel,_that.prenom,_that.nom,_that.domaine,_that.niveau,_that.estActif,_that.avatarUrl,_that.creeLe);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String courriel,  String? prenom,  String? nom,  String? domaine,  String? niveau, @JsonKey(name: 'est_actif')  bool estActif, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'cree_le')  DateTime creeLe)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.id,_that.courriel,_that.prenom,_that.nom,_that.domaine,_that.niveau,_that.estActif,_that.avatarUrl,_that.creeLe);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String courriel,  String? prenom,  String? nom,  String? domaine,  String? niveau, @JsonKey(name: 'est_actif')  bool estActif, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'cree_le')  DateTime creeLe)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.courriel,_that.prenom,_that.nom,_that.domaine,_that.niveau,_that.estActif,_that.avatarUrl,_that.creeLe);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfile implements UserProfile {
  const _UserProfile({required this.id, required this.courriel, this.prenom, this.nom, this.domaine, this.niveau, @JsonKey(name: 'est_actif') required this.estActif, @JsonKey(name: 'avatar_url') this.avatarUrl, @JsonKey(name: 'cree_le') required this.creeLe});
  factory _UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

@override final  String id;
@override final  String courriel;
@override final  String? prenom;
@override final  String? nom;
@override final  String? domaine;
@override final  String? niveau;
@override@JsonKey(name: 'est_actif') final  bool estActif;
@override@JsonKey(name: 'avatar_url') final  String? avatarUrl;
@override@JsonKey(name: 'cree_le') final  DateTime creeLe;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.courriel, courriel) || other.courriel == courriel)&&(identical(other.prenom, prenom) || other.prenom == prenom)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.domaine, domaine) || other.domaine == domaine)&&(identical(other.niveau, niveau) || other.niveau == niveau)&&(identical(other.estActif, estActif) || other.estActif == estActif)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.creeLe, creeLe) || other.creeLe == creeLe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courriel,prenom,nom,domaine,niveau,estActif,avatarUrl,creeLe);

@override
String toString() {
  return 'UserProfile(id: $id, courriel: $courriel, prenom: $prenom, nom: $nom, domaine: $domaine, niveau: $niveau, estActif: $estActif, avatarUrl: $avatarUrl, creeLe: $creeLe)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String courriel, String? prenom, String? nom, String? domaine, String? niveau,@JsonKey(name: 'est_actif') bool estActif,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'cree_le') DateTime creeLe
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? courriel = null,Object? prenom = freezed,Object? nom = freezed,Object? domaine = freezed,Object? niveau = freezed,Object? estActif = null,Object? avatarUrl = freezed,Object? creeLe = null,}) {
  return _then(_UserProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courriel: null == courriel ? _self.courriel : courriel // ignore: cast_nullable_to_non_nullable
as String,prenom: freezed == prenom ? _self.prenom : prenom // ignore: cast_nullable_to_non_nullable
as String?,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,domaine: freezed == domaine ? _self.domaine : domaine // ignore: cast_nullable_to_non_nullable
as String?,niveau: freezed == niveau ? _self.niveau : niveau // ignore: cast_nullable_to_non_nullable
as String?,estActif: null == estActif ? _self.estActif : estActif // ignore: cast_nullable_to_non_nullable
as bool,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,creeLe: null == creeLe ? _self.creeLe : creeLe // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
