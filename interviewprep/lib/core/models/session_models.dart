import 'package:json_annotation/json_annotation.dart';

part 'session_models.g.dart';

@JsonSerializable()
class SessionResponse {
  final String id;
  @JsonKey(name: 'utilisateur_id')
  final String utilisateurId;
  @JsonKey(name: 'exercice_id')
  final String exerciceId;
  @JsonKey(name: 'commence_le')
  final DateTime? commenceLe;
  @JsonKey(name: 'termine_le')
  final DateTime? termineLe;
  final String statut;
  final double? score;
  final List<dynamic>? reponses;

  SessionResponse({
    required this.id,
    required this.utilisateurId,
    required this.exerciceId,
    this.commenceLe,
    this.termineLe,
    required this.statut,
    this.score,
    this.reponses,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SessionResponseToJson(this);
}

@JsonSerializable()
class FeedbackResponse {
  final String id;
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'score_global')
  final double scoreGlobal;
  @JsonKey(name: 'points_forts')
  final List<String> pointsForts;
  final List<String> ameliorations;
  final List<String> recommandations;
  @JsonKey(name: 'genere_le')
  final DateTime? genereLe;

  FeedbackResponse({
    required this.id,
    required this.sessionId,
    required this.scoreGlobal,
    required this.pointsForts,
    required this.ameliorations,
    required this.recommandations,
    this.genereLe,
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) =>
      _$FeedbackResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FeedbackResponseToJson(this);
}
