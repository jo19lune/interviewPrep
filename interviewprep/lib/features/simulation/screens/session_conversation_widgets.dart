import 'package:flutter/material.dart';
import '../../../core/models/session_detail.dart';
import '../../../core/theme/app_theme.dart';

class SessionHeaderCard extends StatelessWidget {
  const SessionHeaderCard({super.key, required this.conversation});

  final SessionConversation conversation;

  @override
  Widget build(BuildContext context) {
    final session = conversation.session;
    final title =
        conversation.exerciseTitle ?? 'Session #${session.id.substring(0, 8)}';
    final date = session.commenceLe == null
        ? ''
        : '${session.commenceLe!.day}/${session.commenceLe!.month}/${session.commenceLe!.year}';
    final score = session.score ?? 0;
    return Card(
      color: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            if ((conversation.exerciseDomaine ?? '').isNotEmpty)
              Text(
                'Domaine: ${conversation.exerciseDomaine}',
                style: const TextStyle(color: AppTheme.onSurfaceVariant),
              ),
            Text(
              'Date: $date',
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            if (session.statut == 'TERMINEE')
              Text(
                'Score: ${score.round()}/100',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: score >= 70
                      ? AppTheme.onTertiaryFixedVariant
                      : score < 50
                      ? AppTheme.error
                      : AppTheme.secondaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
