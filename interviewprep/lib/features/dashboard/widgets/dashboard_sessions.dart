import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/session_models.dart';
import '../../../app/theme/app_theme.dart';

class DashboardSessions extends StatelessWidget {
  const DashboardSessions({required this.sessions, super.key});
  final List<SessionResponse> sessions;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Sessions Récentes',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppTheme.primaryContainer,
              fontSize: 20,
            ),
          ),
          TextButton(
            onPressed: () => context.go('/simulation/history'),
            child: const Text(
              'Voir tout',
              style: TextStyle(color: AppTheme.secondaryColor),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        child: sessions.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Aucune session complétée pour le moment.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : Column(
                children: [
                  for (var i = 0; i < sessions.length; i++) ...[
                    _SessionRow(session: sessions[i]),
                    if (i < sessions.length - 1)
                      const Divider(height: 1, color: AppTheme.outlineVariant),
                  ],
                ],
              ),
      ),
    ],
  );
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});
  final SessionResponse session;

  @override
  Widget build(BuildContext context) {
    final score = session.score ?? 0.0;
    final good = score >= 70;
    final warning = score < 50;
    final indicator = good
        ? AppTheme.tertiaryFixed
        : warning
        ? AppTheme.error
        : AppTheme.outlineVariant;
    final scoreBackground = good
        ? AppTheme.tertiaryFixed
        : warning
        ? AppTheme.error.withAlpha((0.2 * 255).round())
        : AppTheme.outlineVariant.withAlpha((0.2 * 255).round());
    final scoreColor = good
        ? AppTheme.onTertiaryFixedVariant
        : warning
        ? AppTheme.error
        : AppTheme.onSurfaceVariant;
    final date = session.commenceLe == null
        ? 'Inconnue'
        : '${session.commenceLe!.day}/${session.commenceLe!.month}/${session.commenceLe!.year}';
    return InkWell(
      onTap: () => context.push('/simulation/history/${session.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: indicator,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Entretien d\'évaluation',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.primaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Lancé le $date • Statut: ${session.statut}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scoreBackground,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${score.round()}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scoreColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
