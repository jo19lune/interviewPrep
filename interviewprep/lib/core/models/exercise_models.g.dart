// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExerciceCreateRequest _$ExerciceCreateRequestFromJson(
  Map<String, dynamic> json,
) => ExerciceCreateRequest(
  titre: json['titre'] as String,
  description: json['description'] as String,
  domaine: json['domaine'] as String,
  difficulte: json['difficulte'] as String,
  dureeSec: (json['duree_sec'] as num).toInt(),
  questions: json['questions'] as List<dynamic>?,
  etiquettes: (json['etiquettes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ExerciceCreateRequestToJson(
  ExerciceCreateRequest instance,
) => <String, dynamic>{
  'titre': instance.titre,
  'description': instance.description,
  'domaine': instance.domaine,
  'difficulte': instance.difficulte,
  'duree_sec': instance.dureeSec,
  'questions': instance.questions,
  'etiquettes': instance.etiquettes,
};

ExerciceResponse _$ExerciceResponseFromJson(Map<String, dynamic> json) =>
    ExerciceResponse(
      id: json['id'] as String,
      titre: json['titre'] as String,
      description: json['description'] as String,
      domaine: json['domaine'] as String,
      difficulte: json['difficulte'] as String,
      dureeSec: (json['duree_sec'] as num).toInt(),
      questions: json['questions'] as List<dynamic>?,
      etiquettes: (json['etiquettes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      creeLe: json['cree_le'] == null
          ? null
          : DateTime.parse(json['cree_le'] as String),
    );

Map<String, dynamic> _$ExerciceResponseToJson(ExerciceResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titre': instance.titre,
      'description': instance.description,
      'domaine': instance.domaine,
      'difficulte': instance.difficulte,
      'duree_sec': instance.dureeSec,
      'questions': instance.questions,
      'etiquettes': instance.etiquettes,
      'cree_le': instance.creeLe?.toIso8601String(),
    };
