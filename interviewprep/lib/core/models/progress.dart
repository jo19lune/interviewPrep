class ProgressMeResponse {
  final int totalSessions;
  final double avgScore;
  final double bestScore;
  final int streak;
  final DateTime? lastSessionDate;

  const ProgressMeResponse({
    required this.totalSessions,
    required this.avgScore,
    required this.bestScore,
    required this.streak,
    this.lastSessionDate,
  });

  factory ProgressMeResponse.fromJson(Map<String, dynamic> json) =>
      ProgressMeResponse(
        totalSessions: (json['total_sessions'] as num).toInt(),
        avgScore: (json['avg_score'] as num).toDouble(),
        bestScore: (json['best_score'] as num).toDouble(),
        streak: (json['streak'] as num).toInt(),
        lastSessionDate: json['last_session_date'] == null
            ? null
            : DateTime.parse(json['last_session_date'] as String),
      );

  Map<String, dynamic> toJson() => {
    'total_sessions': totalSessions,
    'avg_score': avgScore,
    'best_score': bestScore,
    'streak': streak,
    'last_session_date': lastSessionDate?.toIso8601String(),
  };
}


