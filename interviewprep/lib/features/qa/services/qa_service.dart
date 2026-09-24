import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/chat_message.dart';

class QAService {
  final ApiClient _apiClient = ApiClient();

  Future<String> generateNextQuestion({
    required List<String> previousResponses,
    required String domaine,
    required String difficulte,
    String? sujet,
    required int questionIndex,
    required int totalQuestions,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/qa/next-question',
        data: {
          'previous_responses': previousResponses,
          'domaine': domaine,
          'difficulte': difficulte,
          'sujet': sujet,
          'question_index': questionIndex,
          'total_questions': totalQuestions,
        },
      );
      return response.data['question'] as String? ??
          'Pouvez-vous développer votre réponse ?';
    } on DioException catch (e) {
      throw Exception(
        'Erreur lors de la génération de la question: ${e.message}',
      );
    }
  }

  Future<QAScoreResult> sendAnswer(String questionText, String answer) async {
    try {
      final response = await _apiClient.dio.post(
        '/qa/score-answer',
        data: {'question': questionText, 'answer': answer},
      );
      return QAScoreResult.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Erreur lors de l\'évaluation: ${e.message}');
    }
  }

  Future<QAFeedback> generateFeedback({
    required List<ChatMessage> responses,
    required String contexte,
    String? sujet,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/qa/feedback',
        data: {
          'reponses': responses
              .map(
                (m) => {
                  'id': m.id,
                  'text': m.text,
                  'is_user': m.isUser,
                  'timestamp': m.timestamp.toIso8601String(),
                },
              )
              .toList(),
          'contexte': contexte,
          'sujet': sujet,
        },
      );
      return QAFeedback.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Erreur lors de la génération du feedback: ${e.message}');
    }
  }
}

class QAScoreResult {
  final double score;
  final String sentiment;
  final String coachingTip;
  final Map<String, double> analysis;

  const QAScoreResult({
    required this.score,
    required this.sentiment,
    required this.coachingTip,
    required this.analysis,
  });

  factory QAScoreResult.fromJson(Map<String, dynamic> json) => QAScoreResult(
    score: (json['score'] as num).toDouble(),
    sentiment: json['sentiment'] as String? ?? 'Neutral',
    coachingTip: json['coaching_tip'] as String? ?? '',
    analysis: json['analysis'] != null
        ? Map<String, double>.from(json['analysis'] as Map)
        : const {},
  );

  Map<String, dynamic> toJson() => {
    'score': score,
    'sentiment': sentiment,
    'coaching_tip': coachingTip,
    'analysis': analysis,
  };
}

class QAFeedback {
  final double scoreGlobal;
  final List<QADomainFeedback> pointsForts;
  final List<QADomainFeedback> ameliorations;
  final List<String> recommandations;
  final DateTime genereLe;

  const QAFeedback({
    required this.scoreGlobal,
    required this.pointsForts,
    required this.ameliorations,
    required this.recommandations,
    required this.genereLe,
  });

  factory QAFeedback.fromJson(Map<String, dynamic> json) => QAFeedback(
    scoreGlobal: (json['score_global'] as num).toDouble(),
    pointsForts:
        (json['points_forts'] as List<dynamic>?)
            ?.map((e) => QADomainFeedback.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    ameliorations:
        (json['ameliorations'] as List<dynamic>?)
            ?.map((e) => QADomainFeedback.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    recommandations:
        (json['recommandations'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    genereLe: DateTime.parse((json['genere_le'] ?? json['genereLe']) as String),
  );

  Map<String, dynamic> toJson() => {
    'score_global': scoreGlobal,
    'points_forts': pointsForts.map((e) => e.toJson()).toList(),
    'ameliorations': ameliorations.map((e) => e.toJson()).toList(),
    'recommandations': recommandations,
    'genere_le': genereLe.toIso8601String(),
  };
}

class QADomainFeedback {
  final String domaine;
  final String note;
  final double score;

  const QADomainFeedback({
    required this.domaine,
    required this.note,
    required this.score,
  });

  factory QADomainFeedback.fromJson(Map<String, dynamic> json) =>
      QADomainFeedback(
        domaine: json['domaine'] as String? ?? 'Compétence',
        note: json['note'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
    'domaine': domaine,
    'note': note,
    'score': score,
  };
}
