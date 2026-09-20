import 'package:flutter/material.dart';
import '../../../core/models/progress.dart';
import '../../../core/theme/app_theme.dart';

class DashboardRecommendations extends StatelessWidget {
  const DashboardRecommendations({required this.progress, super.key});
  final ProgressMeResponse progress;

  @override
  Widget build(BuildContext context) {
    final strong = progress.avgScore >= 70;
    final medium = progress.avgScore >= 50;
    final title = strong
        ? 'Excellents résultats'
        : medium
        ? 'Bonne progression'
        : 'Continuer les efforts';
    final subtitle = strong
        ? 'Continuez d\'ajouter des chiffres précis et des indicateurs de succès (KPI) dans vos études de cas.'
        : medium
        ? 'Renforcez la structure STAR dans vos réponses et ajoutez des résultats mesurables.'
        : 'Pratiquez avec des exercices de niveau Débutant et structurez vos réponses avec la méthode STAR.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.recommend, color: AppTheme.primaryContainer),
            const SizedBox(width: 8),
            Text(
              'Personalized Tips',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryContainer,
                fontSize: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Recommendation(
          icon: Icons.lightbulb,
          color: AppTheme.onSecondaryContainer,
          background: AppTheme.secondaryContainer,
          title: title,
          subtitle: subtitle,
        ),
        const SizedBox(height: 16),
        _Recommendation(
          icon: Icons.star_rate,
          color: AppTheme.onTertiaryFixedVariant,
          background: AppTheme.tertiaryFixed,
          title: title,
          subtitle: subtitle,
        ),
      ],
    );
  }
}

class _Recommendation extends StatelessWidget {
  const _Recommendation({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.outlineVariant),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.primaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class DashboardMotivation extends StatelessWidget {
  const DashboardMotivation({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppTheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY\'S FOCUS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.primaryFixedVariant,
            letterSpacing: 1.5,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '"Comment gérez-vous un désaccord avec un manager ?" ',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Cette question comportementale classique apparaît dans 40% des entretiens. Exercez-vous dès aujourd\'hui !',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryFixedVariant),
        ),
      ],
    ),
  );
}
