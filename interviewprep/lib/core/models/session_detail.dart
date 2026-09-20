import 'package:json_annotation/json_annotation.dart';
import 'session_models.dart';

part 'session_detail.g.dart';

@JsonSerializable()
class SessionDetailFeedback {
  final String id;
  @JsonKey(name: 'score_global')
  final double scoreGlobal;
  @JsonKey(name: 'points_forts')
  final List<dynamic> pointsForts;
  final List<dynamic> ameliorations;
  final List<dynamic> recommandations;
  @JsonKey(name: 'genere_le')
  final String? genereLe;

  SessionDetailFeedback({
    required this.id,
    required this.scoreGlobal,
    required this.pointsForts,
    required this.ameliorations,
    required this.recommandations,
    this.genereLe,
  });

  factory SessionDetailFeedback.fromJson(Map<String, dynamic> json) =>
      _$SessionDetailFeedbackFromJson(json);
  Map<String, dynamic> toJson() => _$SessionDetailFeedbackToJson(this);
}

@JsonSerializable()
class SessionConversation {
  final SessionResponse session;
  final SessionDetailFeedback? feedback;
  @JsonKey(name: 'exercise_title')
  final String? exerciseTitle;
  @JsonKey(name: 'exercise_domaine')
  final String? exerciseDomaine;
  @JsonKey(name: 'user_responses')
  final List<dynamic> userResponses;

  SessionConversation({
    required this.session,
    this.feedback,
    this.exerciseTitle,
    this.exerciseDomaine,
    required this.userResponses,
  });

  factory SessionConversation.fromJson(Map<String, dynamic> json) =>
      _$SessionConversationFromJson(json);
  Map<String, dynamic> toJson() => _$SessionConversationToJson(this);
}
