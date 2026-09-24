import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/progress.dart';
import '../../../core/models/user.dart';
import '../../../app/theme/app_theme.dart';

class DashboardHero extends StatelessWidget {
  const DashboardHero({required this.user, required this.progress, super.key});
  final User user;
  final AsyncValue<ProgressMeResponse> progress;

  @override
  Widget build(BuildContext context) => progress.when(
    data: (value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, ${user.prenom ?? ''}.',
          style: Theme.of(
            context,
          ).textTheme.displayLarge?.copyWith(color: AppTheme.primaryContainer),
        ),
        const SizedBox(height: 16),
        Text(
          'Vous avez complété ${value.totalSessions} sessions d\'entraînement. Votre série actuelle est de ${value.streak} jours consécutifs !',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => context.go('/exercises'),
          icon: const Icon(Icons.play_arrow, color: Colors.white),
          label: const Text('Start Training'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _ScoreCard(score: value.bestScore),
      ],
    ),
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, _) => const Center(child: Text('Erreur chargement progression')),
  );
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryContainer.withAlpha((0.05 * 255).round()),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              '✦ AI INSIGHT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 128,
          width: 128,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 12,
                backgroundColor: AppTheme.surfaceContainerLow,
                valueColor: const AlwaysStoppedAnimation(
                  AppTheme.tertiaryFixed,
                ),
              ),
              Center(
                child: Text(
                  '${score.round()}%',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.primaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Score de réussite',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Text(
          'Meilleur score sur toutes vos sessions',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
