import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/session_models.dart';
import '../../../app/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import 'statistics_sections.dart';
import 'statistics_panels.dart';
import 'statistics_summary.dart';

class StatisticsContent extends ConsumerWidget {
  const StatisticsContent({
    required this.selectedPeriod,
    required this.periods,
    required this.onPeriodChanged,
    super.key,
  });
  final String selectedPeriod;
  final List<String> periods;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(detailedStatsProvider);
    final history = ref.watch(sessionHistoryProvider);
    final sessions = _filter(history.value ?? []);
    return RefreshIndicator(
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
            _Header(
              periods: periods,
              selected: selectedPeriod,
              onChanged: onPeriodChanged,
            ),
            const SizedBox(height: 24),
            stats.when(
              data: (value) =>
                  StatisticsSummary(stats: value, sessions: sessions),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  ErrorPanel(message: 'Erreur statistiques : $error'),
            ),
            const SizedBox(height: 24),
            HistoryTrendSection(sessions: sessions),
          ],
        ),
      ),
    );
  }

  List<SessionResponse> _filter(List<SessionResponse> sessions) {
    if (selectedPeriod == 'All') return sessions;
    final duration = selectedPeriod == '7D'
        ? const Duration(days: 7)
        : selectedPeriod == '1M'
        ? const Duration(days: 30)
        : const Duration(days: 90);
    final cutoff = DateTime.now().subtract(duration);
    return sessions
        .where((s) => s.commenceLe != null && s.commenceLe!.isAfter(cutoff))
        .toList();
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.periods,
    required this.selected,
    required this.onChanged,
  });
  final List<String> periods;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
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
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: periods.map((period) {
          final selectedPeriod = period == selected;
          return ChoiceChip(
            label: Text(period),
            selected: selectedPeriod,
            selectedColor: AppTheme.secondaryColor,
            backgroundColor: AppTheme.surfaceContainerLowest,
            labelStyle: TextStyle(
              color: selectedPeriod ? Colors.white : AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onSelected: (_) => onChanged(period),
          );
        }).toList(),
      ),
    ],
  );
}
