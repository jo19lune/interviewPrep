import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../../../app/theme/app_theme.dart';

class ProfileStatusCard extends StatelessWidget {
  const ProfileStatusCard({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final active = profile.estActif;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border.all(color: AppTheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.tertiaryFixed.withValues(alpha: 0.2)
                  : AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              active ? Icons.check_circle : Icons.warning_amber_rounded,
              color: active ? AppTheme.onTertiaryFixedVariant : AppTheme.error,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active
                      ? 'Votre compte est actif'
                      : 'Vérification du compte en attente',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  active
                      ? 'Vos informations personnelles sont stockées en toute sécurité.'
                      : 'Veuillez vérifier votre adresse e-mail pour accéder à toutes les fonctionnalités.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
