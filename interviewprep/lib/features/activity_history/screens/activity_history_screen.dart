import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../providers/activity_history_provider.dart';
import 'activity_history_dialogs.dart';

class ActivityHistoryScreen extends ConsumerWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activityHistoryProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Historique des activités'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(activityHistoryProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openActivityForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erreur : $error', textAlign: TextAlign.center),
          ),
        ),
        data: (activities) {
          if (activities.isEmpty) {
            return const Center(child: Text('Aucune activité enregistrée.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(activityHistoryProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: activities.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Card(
                  color: AppTheme.surfaceContainerLowest,
                  child: ListTile(
                    title: Text(activity.message),
                    subtitle: Text(
                      '${activity.type} • ${formatActivityDate(activity.creeLe)}',
                    ),
                    leading: const CircleAvatar(child: Icon(Icons.event_note)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          openActivityForm(context, ref, activity: activity);
                        }
                        if (action == 'delete') {
                          confirmDeleteActivity(context, ref, activity);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Modifier')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
