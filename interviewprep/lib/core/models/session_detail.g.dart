part of 'session_detail.dart';

SessionDetailFeedback _$SessionDetailFeedbackFromJson(Map<String, dynamic> json) =>
    SessionDetailFeedback(
      id: json['id'] as String,
      scoreGlobal: (json['score_global'] as num).toDouble(),
      pointsForts: json['points_forts'] as List<dynamic>,
      ameliorations: json['ameliorations'] as List<dynamic>,
      recommandations: json['recommandations'] as List<dynamic>,
      genereLe: json['genere_le'] as String?,
    );

Map<String, dynamic> _$SessionDetailFeedbackToJson(SessionDetailFeedback instance) =>
    <String, dynamic>{
      'id': instance.id,
      'score_global': instance.scoreGlobal,
      'points_forts': instance.pointsForts,
      'ameliorations': instance.ameliorations,
      'recommandations': instance.recommandations,
      'genere_le': instance.genereLe,
    };

SessionConversation _$SessionConversationFromJson(Map<String, dynamic> json) =>
    SessionConversation(
      session: SessionResponse.fromJson(json['session'] as Map<String, dynamic>),
      feedback: json['feedback'] == null
          ? null
          : SessionDetailFeedback.fromJson(json['feedback'] as Map<String, dynamic>),
      exerciseTitle: json['exercise_title'] as String?,
      exerciseDomaine: json['exercise_domaine'] as String?,
      userResponses: json['user_responses'] as List<dynamic>,
    );

Map<String, dynamic> _$SessionConversationToJson(SessionConversation instance) =>
    <String, dynamic>{
      'session': instance.session.toJson(),
      'feedback': instance.feedback?.toJson(),
      'exercise_title': instance.exerciseTitle,
      'exercise_domaine': instance.exerciseDomaine,
      'user_responses': instance.userResponses,
    };
