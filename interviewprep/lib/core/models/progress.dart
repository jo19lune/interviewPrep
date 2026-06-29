class DomainStats {
  final String domaine;
  final int total;
  final double avgScore;
  final double bestScore;

  const DomainStats({
    required this.domaine,
    required this.total,
    required this.avgScore,
    required this.bestScore,
  });

  factory DomainStats.fromJson(Map<String, dynamic> json) => DomainStats(
    domaine: json['domaine'] as String,
    total: (json['total'] as num).toInt(),
    avgScore: (json['avg_score'] as num).toDouble(),
    bestScore: (json['best_score'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'domaine': domaine,
    'total': total,
    'avg_score': avgScore,
    'best_score': bestScore,
  };
}

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

class ProgressStatsResponse {
  final Map<String, DomainStats> domaines;

  const ProgressStatsResponse({required this.domaines});

  factory ProgressStatsResponse.fromJson(Map<String, dynamic> json) {
    final map = <String, DomainStats>{};
    for (final entry in json.entries) {
      if (entry.value is Map) {
        map[entry.key] = DomainStats.fromJson(entry.value as Map<String, dynamic>);
      }
    }
    return ProgressStatsResponse(domaines: map);
  }

  Map<String, dynamic> toJson() => {
    for (final entry in domaines.entries) entry.key: entry.value.toJson(),
  };
}

double getStreakLevel(int streak) {
  if (streak >= 14) return 95.0;
  if (streak >= 7) return 85.0;
  if (streak >= 3) return 70.0;
  if (streak >= 1) return 55.0;
  return 40.0;
}
