class ActivityHistory {
  final String id;
  final String utilisateurId;
  final String type;
  final String message;
  final Map<String, dynamic>? metadata;
  final DateTime creeLe;
  final DateTime modifieLe;

  const ActivityHistory({
    required this.id,
    required this.utilisateurId,
    required this.type,
    required this.message,
    required this.metadata,
    required this.creeLe,
    required this.modifieLe,
  });

  factory ActivityHistory.fromJson(Map<String, dynamic> json) {
    return ActivityHistory(
      id: json['id'] as String,
      utilisateurId: json['utilisateur_id'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
      creeLe: DateTime.parse(json['cree_le'] as String),
      modifieLe: DateTime.parse(json['modifie_le'] as String),
    );
  }
}
