import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

void showStandaloneQAExitDialog(BuildContext context, VoidCallback onExit) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      title: const Text('Quitter la session ?'),
      content: const Text(
        'La session en cours sera abandonnée. Voulez-vous continuer ?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Continuer la session'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogCtx);
            onExit();
          },
          child: const Text('Quitter', style: TextStyle(color: AppTheme.error)),
        ),
      ],
    ),
  );
}
