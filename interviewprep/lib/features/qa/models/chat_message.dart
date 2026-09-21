class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final double? scorePartiel;
  final String? sentiment;
  final String? coachingTip;
  final Map<String, dynamic>? analysis;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.scorePartiel,
    this.sentiment,
    this.coachingTip,
    this.analysis,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    double? scorePartiel,
    String? sentiment,
    String? coachingTip,
    Map<String, dynamic>? analysis,
    bool clearAnalysis = false,
    bool clearCoachingTip = false,
    bool clearSentiment = false,
    bool clearScorePartiel = false,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      scorePartiel: clearScorePartiel ? null : (scorePartiel ?? this.scorePartiel),
      sentiment: clearSentiment ? null : (sentiment ?? this.sentiment),
      coachingTip: clearCoachingTip ? null : (coachingTip ?? this.coachingTip),
      analysis: clearAnalysis ? null : (analysis ?? this.analysis),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'is_user': isUser,
    'timestamp': timestamp.toIso8601String(),
    'score_partiel': scorePartiel,
    'sentiment': sentiment,
    'coaching_tip': coachingTip,
    'analysis': analysis,
  };
}

class QASessionConfig {
  final String? subject;
  final int totalQuestions;

  const QASessionConfig({this.subject, required this.totalQuestions});

  QASessionConfig copyWith({String? subject, int? totalQuestions}) {
    return QASessionConfig(
      subject: subject ?? this.subject,
      totalQuestions: totalQuestions ?? this.totalQuestions,
    );
  }
}
