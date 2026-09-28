import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/activity_history.dart';
import '../providers/activity_history_provider.dart';

String formatActivityDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

/// Ouvre le formulaire de création ou de modification d'une activité.
/// Lève `true` lorsque l'enregistrement a réussi.
Future<void> openActivityForm(
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
      title: Text(activity == null ? 'Nouvelle activité' : 'Modifier l’activité'),
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

/// Demande confirmation puis supprime l'activité.
Future<void> confirmDeleteActivity(
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
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
