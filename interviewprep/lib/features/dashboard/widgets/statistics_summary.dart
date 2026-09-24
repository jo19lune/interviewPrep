import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/session_models.dart';
import '../../../app/theme/app_theme.dart';
import '../../exercises/providers/exercise_provider.dart';
import 'statistics_sections.dart';
import 'statistics_cards.dart';

class StatisticsSummary extends ConsumerWidget {
  const StatisticsSummary({
    required this.stats,
    required this.sessions,
    super.key,
  });
  final Map<String, dynamic> stats;
  final List<SessionResponse> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = sessions.where((s) => s.statut == 'TERMINEE').toList();
    final entries = stats.entries
        .where(
          (e) => e.value is Map && (e.value as Map).containsKey('avg_score'),
        )
        .toList();
    var weight = 0;
    var weighted = 0.0;
    for (final entry in entries) {
      final data = entry.value as Map;
      final count = (data['total'] as num?)?.toInt() ?? 1;
      weighted += (data['avg_score'] as num).toDouble() * count;
      weight += count;
    }
    var hours = 0.0;
    for (final session in completed) {
      if (session.termineLe != null && session.commenceLe != null) {
        hours +=
            session.termineLe!.difference(session.commenceLe!).inMinutes / 60;
      }
    }
    final average = entries.isEmpty
        ? 0.0
        : entries
                  .map((e) => (e.value as Map)['avg_score'] as num)
                  .reduce((a, b) => a + b) /
              entries.length;
    final title = average >= 70
        ? 'Performance Élevée'
        : average >= 50
        ? 'Développement Équilibré'
        : 'Besoins d\'Amélioration';
    final description = average >= 70
        ? 'Votre performance globale est excellente. Continuez à maintenir ce niveau et explorez de nouveaux domaines pour élargir vos compétences.'
        : average >= 50
        ? 'Votre profil est solide, mais vous pouvez gagner en impact en structurant chaque réponse avec plus de précision et d\'exemples mesurables.'
        : 'Continuez à vous entraîner régulièrement. Concentrez-vous sur les domaines avec les scores les plus bas pour améliorer votre performance globale.';
    final top = entries.isEmpty
        ? ''
        : _domain(
            entries
                .reduce(
                  (a, b) =>
                      (a.value as Map)['avg_score'] >
                          (b.value as Map)['avg_score']
                      ? a
                      : b,
                )
                .key,
          );
    final exercises = ref.watch(exercisesListProvider).value ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            MetricCard(
              icon: Icons.rocket,
              label: 'Total Simulations',
              value: '${completed.length}',
              color: AppTheme.secondaryColor,
            ),
            MetricCard(
              icon: Icons.pie_chart,
              label: 'Avg Clarity',
              value: '${(weight == 0 ? 0 : weighted / weight).round()}%',
              color: AppTheme.primaryContainer,
            ),
            MetricCard(
              icon: Icons.access_time,
              label: 'Hours Practiced',
              value: '${hours.toStringAsFixed(1)}h',
              color: AppTheme.tertiaryFixed,
            ),
            MetricCard(
              icon: Icons.badge,
              label: 'Top Role',
              value: top,
              color: AppTheme.primaryFixedVariant,
              large: true,
            ),
          ],
        ),
        const SizedBox(height: 24),
        InsightCard(
          title: title,
          description: description,
          onPractice: exercises.isEmpty
              ? null
              : () {
                  final list = List.from(exercises)..shuffle();
                  ref
                      .read(selectedExerciseProvider.notifier)
                      .select(list.first);
                  context.go('/simulation');
                },
        ),
        const SizedBox(height: 24),
        SkillProficiencySection(entries: entries),
      ],
    );
  }

  String _domain(String value) =>
      {
        'TECHNIQUE': 'Technique',
        'COMPORTEMENTAL': 'Comportemental',
        'SITUATIONNEL': 'Situations',
        'ETUDE_DE_CAS': 'Études de cas',
        'MOTIVATION': 'Motivation',
      }[value] ??
      value;
}
