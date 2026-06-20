import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bottom_navigation.dart';
import '../../../core/models/exercise.dart';
import '../providers/dashboard_provider.dart';
import '../../exercises/providers/exercise_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  static const _periods = ['7D', '1M', '3M', 'All'];

  String _domainToFrench(String domaine) {
    switch (domaine) {
      case 'TECHNIQUE':
        return 'Technique';
      case 'COMPORTEMENTAL':
        return 'Comportemental';
      case 'SITUATIONNEL':
        return 'Situations';
      case 'ETUDE_DE_CAS':
        return 'Études de cas';
      case 'MOTIVATION':
        return 'Motivation';
      default:
        return domaine;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(detailedStatsProvider);
    final historyAsync = ref.watch(sessionHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        title: const Text(
          'Insights',
          style: TextStyle(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryContainer),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(detailedStatsProvider);
          ref.invalidate(sessionHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              statsAsync.when(
                data: (stats) {
                  final sessions = historyAsync.value ?? [];
                  final exercises = ref.watch(exercisesListProvider).value ?? [];
                  return _buildStatsSummary(context, ref, stats, sessions, exercises);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorPanel(message: 'Erreur statistiques : $error'),
              ),
              const SizedBox(height: 24),
              historyAsync.when(
                data: (sessions) => _HistoryTrendSection(sessions: sessions),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorPanel(message: 'Erreur historique : $error'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNavigation(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Analytics',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryContainer,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Suivez votre progression, comparez vos scores et identifiez les axes d\'amélioration les plus importants.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _periods.map((period) {
            final bool selected = period == _periods.first;
            return ChoiceChip(
              label: Text(period),
              selected: selected,
              selectedColor: AppTheme.secondaryColor,
              backgroundColor: AppTheme.surfaceContainerLowest,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onSelected: (_) {},
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatsSummary(BuildContext context, WidgetRef ref, Map<String, dynamic> stats, List<Session> sessions, List exercises) {
    final terminatedSessions = sessions.where((s) => s.statut == 'TERMINEE').toList();
    final totalSimulations = terminatedSessions.length;

    final domainEntries = stats.entries
        .where((entry) => entry.value is Map && (entry.value as Map).containsKey('avg_score'))
        .toList();

    double avgClarity = 0.0;
    if (domainEntries.isNotEmpty) {
      avgClarity = domainEntries
          .map((e) => (e.value as Map)['avg_score'] as num)
          .reduce((a, b) => a + b) / domainEntries.length;
    }

    double hoursPracticed = 0.0;
    for (final session in terminatedSessions) {
      if (session.termineLe != null) {
        final diff = session.termineLe!.difference(session.commenceLe);
        hoursPracticed += diff.inMinutes / 60.0;
      }
    }

    String topRole = '';
    if (domainEntries.isNotEmpty) {
      final topEntry = domainEntries.reduce((a, b) =>
          (a.value as Map)['avg_score'] > (b.value as Map)['avg_score'] ? a : b);
      topRole = _domainToFrench(topEntry.key);
    }

    double overallAvg = 0.0;
    String insightTitle;
    String insightDescription;
    if (domainEntries.isNotEmpty) {
      overallAvg = domainEntries
          .map((e) => (e.value as Map)['avg_score'] as num)
          .reduce((a, b) => a + b) / domainEntries.length;
    }

    if (overallAvg >= 70) {
      insightTitle = 'Performance Élevée';
      insightDescription = 'Votre performance globale est excellente. Continuez à maintenir ce niveau et explorez de nouveaux domaines pour élargir vos compétences.';
    } else if (overallAvg >= 50) {
      insightTitle = 'Développement Équilibré';
      insightDescription = 'Votre profil est solide, mais vous pouvez gagner en impact en structurant chaque réponse avec plus de précision et d\'exemples mesurables.';
    } else {
      insightTitle = 'Besoins d\'Amélioration';
      insightDescription = 'Continuez à vous entraîner régulièrement. Concentrez-vous sur les domaines avec les scores les plus bas pour améliorer votre performance globale.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          runSpacing: 16,
          spacing: 16,
          children: [
            _MetricCard(
              icon: Icons.rocket,
              label: 'Total Simulations',
              value: '$totalSimulations',
              color: AppTheme.secondaryColor,
            ),
            _MetricCard(
              icon: Icons.pie_chart,
              label: 'Avg Clarity',
              value: '${avgClarity.round()}%',
              color: AppTheme.primaryContainer,
            ),
            _MetricCard(
              icon: Icons.access_time,
              label: 'Hours Practiced',
              value: '${hoursPracticed.toStringAsFixed(1)}h',
              color: AppTheme.tertiaryFixed,
            ),
            _MetricCard(
              icon: Icons.badge,
              label: 'Top Role',
              value: topRole,
              color: AppTheme.primaryFixedVariant,
              isLarge: true,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _InsightCard(
          title: insightTitle,
          description: insightDescription,
          onPractice: exercises.isEmpty
              ? null
              : () {
                  // Prend un exercice aléatoire parmi les disponibles
                  final list = List.from(exercises);
                  list.shuffle();
                  final exercise = list.first;
                  ref.read(selectedExerciseProvider.notifier).state = exercise;
                  context.go('/simulation');
                },
        ),
        const SizedBox(height: 24),
        _SkillProficiencySection(skillEntries: domainEntries),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLarge;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isLarge ? 260 : 140,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryContainer.withAlpha((0.04 * 255).round()),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha((0.16 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold, fontSize: isLarge ? 22 : 20)),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onPractice;

  const _InsightCard({
    required this.title,
    required this.description,
    this.onPractice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('AI Insight'.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white.withAlpha((0.88 * 255).round())),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onPractice,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Démarrer une pratique suggérée',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceContainerLowest,
              foregroundColor: AppTheme.primaryContainer,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillProficiencySection extends StatelessWidget {
  final List<MapEntry<String, dynamic>> skillEntries;

  const _SkillProficiencySection({required this.skillEntries});

  @override
  Widget build(BuildContext context) {
    final entries = skillEntries;

    if (entries.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Aucune donnée de compétence disponible',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skill Proficiency', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold, fontSize: 22)),
          const SizedBox(height: 22),
          ...entries.map((entry) {
            final score = ((entry.value as Map)['avg_score'] as num?)?.toDouble() ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurface, fontWeight: FontWeight.bold)),
                      Text('${score.round()}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: (score / 100).clamp(0, 1),
                      minHeight: 14,
                      backgroundColor: AppTheme.surfaceContainerLow,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
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

class _HistoryTrendSection extends StatelessWidget {
  final List<Session> sessions;

  const _HistoryTrendSection({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final completed = sessions.where((session) => session.statut == 'TERMINEE').take(8).toList();
    if (completed.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.timeline,
        title: 'Pas encore de tendance',
        message: 'Votre courbe apparaitra apres vos prochaines sessions terminees.',
      );
    }

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Derniers scores', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final session in completed.reversed)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _ScoreColumn(score: session.score),
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
  final double score;

  const _ScoreColumn({required this.score});

  @override
  Widget build(BuildContext context) {
    final height = (24 + (score / 100).clamp(0, 1) * 120).toDouble();
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('${score.round()}%', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: score >= 70 ? AppTheme.tertiaryFixed : AppTheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyPanel({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: AppTheme.secondaryColor),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;

  const _ErrorPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withAlpha((0.16 * 255).round())),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.error)),
    );
  }
}
