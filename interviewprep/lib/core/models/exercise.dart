import 'package:json_annotation/json_annotation.dart';
part 'exercise.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Exercise {
  final String id;
  final String titre;
  final String? description;
  final String domaine;
  final String difficulte;
  final int dureeSec;
  final List<dynamic> questions;
  final List<String>? etiquettes;
  final DateTime creeLe;

  const Exercise({
    required this.id,
    required this.titre,
    this.description,
    required this.domaine,
    required this.difficulte,
    required this.dureeSec,
    required this.questions,
    this.etiquettes,
    required this.creeLe,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => _$ExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UserProgress {
  final int totalSessions;
  final double avgScore;
  final double bestScore;
  final int streak;
  final DateTime? lastSessionDate;

  const UserProgress({
    required this.totalSessions,
    required this.avgScore,
    required this.bestScore,
    required this.streak,
    this.lastSessionDate,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) => _$UserProgressFromJson(json);
  Map<String, dynamic> toJson() => _$UserProgressToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Session {
  final String id;
  final String utilisateurId;
  final String exerciceId;
  final DateTime commenceLe;
  final DateTime? termineLe;
  final String statut;
  final double score;
  final List<dynamic>? reponses;

  const Session({
    required this.id,
    required this.utilisateurId,
    required this.exerciceId,
    required this.commenceLe,
    this.termineLe,
    required this.statut,
    required this.score,
    this.reponses,
  });

  factory Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);
  Map<String, dynamic> toJson() => _$SessionToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class StartSimulationResponse {
  final String sessionId;
  final String status;
  final String exerciseTitle;
  final String? firstQuestion;

  const StartSimulationResponse({
    required this.sessionId,
    required this.status,
    required this.exerciseTitle,
    this.firstQuestion,
  });

  factory StartSimulationResponse.fromJson(Map<String, dynamic> json) => _$StartSimulationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StartSimulationResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Feedback {
  final String id;
  final String sessionId;
  final double scoreGlobal;
  final List<dynamic>? pointsForts;
  final List<dynamic>? ameliorations;
  final List<String>? recommandations;
  final DateTime genereLe;

  const Feedback({
    required this.id,
    required this.sessionId,
    required this.scoreGlobal,
    this.pointsForts,
    this.ameliorations,
    this.recommandations,
    required this.genereLe,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) => _$FeedbackFromJson(json);
  Map<String, dynamic> toJson() => _$FeedbackToJson(this);
}
