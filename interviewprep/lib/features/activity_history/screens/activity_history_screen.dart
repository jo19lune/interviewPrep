import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/activity_history.dart';
import '../../../app/theme/app_theme.dart';
import '../providers/activity_history_provider.dart';

class ActivityHistoryScreen extends ConsumerWidget {
  const ActivityHistoryScreen({super.key});

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    ActivityHistory? activity,
  }) async {
    final typeController = TextEditingController(text: activity?.type ?? '');
    final messageController = TextEditingController(
      text: activity?.message ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          activity == null ? 'Nouvelle activité' : 'Modifier l’activité',
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: typeController,
                decoration: const InputDecoration(labelText: 'Type'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Le type est obligatoire'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 3,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Le message est obligatoire'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final service = ref.read(activityHistoryServiceProvider);
              try {
                if (activity == null) {
                  await service.create(
                    type: typeController.text.trim(),
                    message: messageController.text.trim(),
                  );
                } else {
                  await service.update(
                    activity.id,
                    type: typeController.text.trim(),
                    message: messageController.text.trim(),
                  );
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    typeController.dispose();
    messageController.dispose();
    if (result == true) ref.invalidate(activityHistoryProvider);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ActivityHistory activity,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer l’activité ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(activityHistoryServiceProvider).delete(activity.id);
      ref.invalidate(activityHistoryProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

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
        onPressed: () => _openForm(context, ref),
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
                      '${activity.type} • ${_formatDate(activity.creeLe)}',
                    ),
                    leading: const CircleAvatar(child: Icon(Icons.event_note)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit')
                          _openForm(context, ref, activity: activity);
                        if (action == 'delete') _delete(context, ref, activity);
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
