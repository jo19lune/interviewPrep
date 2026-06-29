// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionResponse _$SessionResponseFromJson(Map<String, dynamic> json) =>
    SessionResponse(
      id: json['id'] as String,
      utilisateurId: json['utilisateur_id'] as String,
      exerciceId: json['exercice_id'] as String,
      commenceLe: json['commence_le'] == null
          ? null
          : DateTime.parse(json['commence_le'] as String),
      termineLe: json['termine_le'] == null
          ? null
          : DateTime.parse(json['termine_le'] as String),
      statut: json['statut'] as String,
      score: (json['score'] as num?)?.toDouble(),
      reponses: json['reponses'] as List<dynamic>?,
    );

Map<String, dynamic> _$SessionResponseToJson(SessionResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'utilisateur_id': instance.utilisateurId,
      'exercice_id': instance.exerciceId,
      'commence_le': instance.commenceLe?.toIso8601String(),
      'termine_le': instance.termineLe?.toIso8601String(),
      'statut': instance.statut,
      'score': instance.score,
      'reponses': instance.reponses,
    };

FeedbackResponse _$FeedbackResponseFromJson(Map<String, dynamic> json) =>
    FeedbackResponse(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      scoreGlobal: (json['score_global'] as num).toDouble(),
      pointsForts: (json['points_forts'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      ameliorations: (json['ameliorations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      recommandations: (json['recommandations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      genereLe: json['genere_le'] == null
          ? null
          : DateTime.parse(json['genere_le'] as String),
    );

Map<String, dynamic> _$FeedbackResponseToJson(FeedbackResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'session_id': instance.sessionId,
      'score_global': instance.scoreGlobal,
      'points_forts': instance.pointsForts,
      'ameliorations': instance.ameliorations,
      'recommandations': instance.recommandations,
      'genere_le': instance.genereLe?.toIso8601String(),
    };
