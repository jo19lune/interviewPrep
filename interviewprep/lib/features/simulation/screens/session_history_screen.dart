import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'session_history_tile.dart';

class SessionHistoryScreen extends ConsumerWidget {
  const SessionHistoryScreen({super.key});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _statusLabel(String statut) {
    switch (statut) {
      case 'TERMINEE':
        return 'Terminée';
      case 'EN_COURS':
        return 'En cours';
      case 'ANNULEE':
        return 'Annulée';
      default:
        return statut;
    }
  }

  Color _statusColor(String statut) {
    switch (statut) {
      case 'TERMINEE':
        return AppTheme.tertiaryFixed;
      case 'EN_COURS':
        return AppTheme.secondaryColor;
      case 'ANNULEE':
        return AppTheme.error;
      default:
        return AppTheme.onSurfaceVariant;
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
          style: TextStyle(
            color: AppTheme.primaryContainer,
            fontWeight: FontWeight.bold,
          ),
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
                    Icon(
                      Icons.history,
                      size: 64,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune session pour le moment',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lancez une simulation d\'entretien pour voir votre historique ici.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
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
                return SessionHistoryTile(
                  session: session,
                  formatDate: _formatDate,
                  statusLabel: _statusLabel,
                  statusColor: _statusColor,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Erreur: $e',
              style: const TextStyle(color: AppTheme.error),
            ),
          ),
        ),
      ),
    );
  }
}
