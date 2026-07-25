import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class SessionHistoryScreen extends ConsumerWidget {
  const SessionHistoryScreen({super.key});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _statusLabel(String statut) {
    switch (statut) {
      case 'TERMINEE': return 'Terminée';
      case 'EN_COURS': return 'En cours';
      case 'ANNULEE': return 'Annulée';
      default: return statut;
    }
  }

  Color _statusColor(String statut) {
    switch (statut) {
      case 'TERMINEE': return AppTheme.tertiaryFixed;
      case 'EN_COURS': return AppTheme.secondaryColor;
      case 'ANNULEE': return AppTheme.error;
      default: return AppTheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(allSessionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        title: const Text(
          'Historique des sessions',
          style: TextStyle(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryContainer),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(allSessionsProvider),
        child: sessionsAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 64, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text('Aucune session pour le moment',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Text('Lancez une simulation d\'entretien pour voir votre historique ici.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final session = sessions[index];
                final score = session.score ?? 0.0;
                final isGood = score >= 70.0;
                final isWarning = score < 50.0 && session.statut == 'TERMINEE';
                return Card(
                  color: AppTheme.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push('/simulation/history/${session.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _statusColor(session.statut).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(_statusLabel(session.statut),
                                        style: TextStyle(fontSize: 11, color: _statusColor(session.statut), fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_formatDate(session.commenceLe),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Session #${session.id.substring(0, 8)}',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.onSurface)),
                              ],
                            ),
                          ),
                          if (session.statut == 'TERMINEE')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isGood ? AppTheme.tertiaryFixed.withValues(alpha: 0.15) :
                                       isWarning ? AppTheme.error.withValues(alpha: 0.15) :
                                       AppTheme.secondaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${score.round()}%',
                                style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold,
                                  color: isGood ? AppTheme.onTertiaryFixedVariant :
                                         isWarning ? AppTheme.error :
                                         AppTheme.secondaryColor)),
                            ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.error))),
        ),
      ),
    );
  }
}
