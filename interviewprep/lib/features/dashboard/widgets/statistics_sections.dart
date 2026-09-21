import 'package:flutter/material.dart';
import '../../../core/models/session_models.dart';
import '../../../app/theme/app_theme.dart';
import 'statistics_panels.dart';

class SkillProficiencySection extends StatelessWidget {
  const SkillProficiencySection({required this.entries, super.key});
  final List<MapEntry<String, dynamic>> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty)
      return Panel(
        child: Text(
          'Aucune donnée de compétence disponible',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
      );
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skill Proficiency',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppTheme.primaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 22),
          ...entries.map((entry) {
            final score =
                ((entry.value as Map)['avg_score'] as num?)?.toDouble() ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${score.round()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: (score / 100).clamp(0, 1),
                      minHeight: 14,
                      backgroundColor: AppTheme.surfaceContainerLow,
                      valueColor: const AlwaysStoppedAnimation(
                        AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class HistoryTrendSection extends StatelessWidget {
  const HistoryTrendSection({required this.sessions, super.key});
  final List<SessionResponse> sessions;

  @override
  Widget build(BuildContext context) {
    final completed = sessions
        .where((s) => s.statut == 'TERMINEE')
        .take(8)
        .toList();
    if (completed.isEmpty)
      return const EmptyPanel(
        icon: Icons.timeline,
        title: 'Pas encore de tendance',
        message:
            'Votre courbe apparaitra apres vos prochaines sessions terminees.',
      );
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Derniers scores',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.primaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final session in completed.reversed)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _ScoreColumn(score: session.score ?? 0),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  const _ScoreColumn({required this.score});
  final double score;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('${score.round()}%', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 6),
      Container(
        height: 24 + (score / 100).clamp(0, 1) * 120,
        decoration: BoxDecoration(
          color: score >= 70
              ? AppTheme.tertiaryFixed
              : AppTheme.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ],
  );
}
