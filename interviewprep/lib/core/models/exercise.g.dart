// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Exercise _$ExerciseFromJson(Map<String, dynamic> json) => Exercise(
  id: json['id'] as String,
  titre: json['titre'] as String,
  description: json['description'] as String?,
  domaine: json['domaine'] as String,
  difficulte: json['difficulte'] as String,
  dureeSec: (json['duree_sec'] as num).toInt(),
  questions: json['questions'] as List<dynamic>,
  etiquettes: (json['etiquettes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  creeLe: DateTime.parse(json['cree_le'] as String),
);

Map<String, dynamic> _$ExerciseToJson(Exercise instance) => <String, dynamic>{
  'id': instance.id,
  'titre': instance.titre,
  'description': instance.description,
  'domaine': instance.domaine,
  'difficulte': instance.difficulte,
  'duree_sec': instance.dureeSec,
  'questions': instance.questions,
  'etiquettes': instance.etiquettes,
  'cree_le': instance.creeLe.toIso8601String(),
};

UserProgress _$UserProgressFromJson(Map<String, dynamic> json) => UserProgress(
  totalSessions: (json['total_sessions'] as num).toInt(),
  avgScore: (json['avg_score'] as num).toDouble(),
  bestScore: (json['best_score'] as num).toDouble(),
  streak: (json['streak'] as num).toInt(),
  lastSessionDate: json['last_session_date'] == null
      ? null
      : DateTime.parse(json['last_session_date'] as String),
);

Map<String, dynamic> _$UserProgressToJson(UserProgress instance) =>
    <String, dynamic>{
      'total_sessions': instance.totalSessions,
      'avg_score': instance.avgScore,
      'best_score': instance.bestScore,
      'streak': instance.streak,
      'last_session_date': instance.lastSessionDate?.toIso8601String(),
    };

Session _$SessionFromJson(Map<String, dynamic> json) => Session(
  id: json['id'] as String,
  utilisateurId: json['utilisateur_id'] as String,
  exerciceId: json['exercice_id'] as String,
  commenceLe: DateTime.parse(json['commence_le'] as String),
  termineLe: json['termine_le'] == null
      ? null
      : DateTime.parse(json['termine_le'] as String),
  statut: json['statut'] as String,
  score: (json['score'] as num).toDouble(),
  reponses: json['reponses'] as List<dynamic>?,
);

Map<String, dynamic> _$SessionToJson(Session instance) => <String, dynamic>{
  'id': instance.id,
  'utilisateur_id': instance.utilisateurId,
  'exercice_id': instance.exerciceId,
  'commence_le': instance.commenceLe.toIso8601String(),
  'termine_le': instance.termineLe?.toIso8601String(),
  'statut': instance.statut,
  'score': instance.score,
  'reponses': instance.reponses,
};

StartSimulationResponse _$StartSimulationResponseFromJson(
  Map<String, dynamic> json,
) => StartSimulationResponse(
  sessionId: json['session_id'] as String,
  status: json['status'] as String,
  exerciseTitle: json['exercise_title'] as String,
  firstQuestion: json['first_question'] as String?,
  subject: json['subject'] as String?,
  questionCount: (json['question_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$StartSimulationResponseToJson(
  StartSimulationResponse instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'status': instance.status,
  'exercise_title': instance.exerciseTitle,
  'first_question': instance.firstQuestion,
  'subject': instance.subject,
  'question_count': instance.questionCount,
};

Feedback _$FeedbackFromJson(Map<String, dynamic> json) => Feedback(
  id: json['id'] as String,
  sessionId: json['session_id'] as String,
  scoreGlobal: (json['score_global'] as num).toDouble(),
  pointsForts: json['points_forts'] as List<dynamic>?,
  ameliorations: json['ameliorations'] as List<dynamic>?,
  recommandations: (json['recommandations'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  genereLe: DateTime.parse(json['genere_le'] as String),
);

Map<String, dynamic> _$FeedbackToJson(Feedback instance) => <String, dynamic>{
  'id': instance.id,
  'session_id': instance.sessionId,
  'score_global': instance.scoreGlobal,
  'points_forts': instance.pointsForts,
  'ameliorations': instance.ameliorations,
  'recommandations': instance.recommandations,
  'genere_le': instance.genereLe.toIso8601String(),
};
