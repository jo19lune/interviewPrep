import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

Future<bool> showProfileConfirmation(
  BuildContext context,
  String title,
  String content,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          title: Text(
            title,
            style: const TextStyle(color: AppTheme.primaryContainer),
          ),
          content: Text(
            content,
            style: const TextStyle(color: AppTheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ) ??
      false;
}
