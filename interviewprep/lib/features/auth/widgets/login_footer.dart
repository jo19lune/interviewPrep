import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({required this.onForgetAccount, super.key});
  final VoidCallback onForgetAccount;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.gpp_maybe_outlined,
            color: AppTheme.outline,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'We value your privacy. InterviewPrep is fully GDPR compliant and uses enterprise-grade encryption.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegalButton(
            title: 'Conditions Générales d\'Utilisation',
            content: 'Contenu des CGU... (à compléter)',
            label: 'Terms of Service',
            semantics: 'Lire les conditions générales d\'utilisation',
          ),
          const SizedBox(width: 8),
          _LegalButton(
            title: 'Politique de confidentialité',
            content:
                'InterviewPrep respecte votre vie privée. Vos données d\'entraînement sont sécurisées et traitées conformément au RGPD pour vous fournir des analyses de performance de qualité. Vous pouvez à tout moment exercer votre droit à l\'oubli.',
            label: 'Privacy Policy',
            semantics: 'Lire la politique de confidentialité',
          ),
        ],
      ),
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: onForgetAccount,
        icon: const Icon(Icons.delete_forever, size: 14, color: AppTheme.error),
        label: Text(
          'Right to be forgotten',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppTheme.error),
        ),
      ),
    ],
  );
}

class _LegalButton extends StatelessWidget {
  const _LegalButton({
    required this.title,
    required this.content,
    required this.label,
    required this.semantics,
  });
  final String title;
  final String content;
  final String label;
  final String semantics;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semantics,
    button: true,
    child: TextButton(
      onPressed: () => showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppTheme.secondaryColor),
      ),
    ),
  );
}
