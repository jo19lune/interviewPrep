import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/session_models.dart';
import '../../../core/theme/app_theme.dart';

class SessionHistoryTile extends StatelessWidget {
  const SessionHistoryTile({
    super.key,
    required this.session,
    required this.formatDate,
    required this.statusLabel,
    required this.statusColor,
  });

  final SessionResponse session;
  final String Function(DateTime?) formatDate;
  final String Function(String) statusLabel;
  final Color Function(String) statusColor;

  @override
  Widget build(BuildContext context) {
    final score = session.score ?? 0.0;
    final good = score >= 70;
    final warning = score < 50 && session.statut == 'TERMINEE';
    return Card(
      color: AppTheme.surfaceContainerLowest,
      child: ListTile(
        onTap: () => context.push('/simulation/history/${session.id}'),
        leading: Text(statusLabel(session.statut)),
        title: Text('Session #${session.id.substring(0, 8)}'),
        subtitle: Text(formatDate(session.commenceLe)),
        trailing: session.statut != 'TERMINEE'
            ? const Icon(Icons.chevron_right)
            : Text(
                '${score.round()}%',
                style: TextStyle(
                  color: good
                      ? AppTheme.onTertiaryFixedVariant
                      : warning
                      ? AppTheme.error
                      : AppTheme.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
