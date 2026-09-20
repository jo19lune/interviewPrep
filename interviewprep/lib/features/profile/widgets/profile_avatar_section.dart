import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProfileAvatarSection extends StatelessWidget {
  const ProfileAvatarSection({
    super.key,
    required this.avatarUrl,
    required this.isSaving,
    required this.onPick,
    required this.onDelete,
  });

  final String? avatarUrl;
  final bool isSaving;
  final VoidCallback onPick;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: isSaving ? null : onPick,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppTheme.surfaceContainerLow,
                    backgroundImage: avatarUrl == null
                        ? null
                        : NetworkImage(avatarUrl!),
                    child: avatarUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 52,
                            color: AppTheme.primaryContainer,
                          )
                        : null,
                  ),
                  if (isSaving)
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.3 * 255).round()),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
              if (!isSaving)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppTheme.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          avatarUrl == null ? 'Aucun avatar défini' : "Modifier l'avatar",
          style: TextStyle(
            fontSize: 14,
            color: avatarUrl == null
                ? AppTheme.outline
                : AppTheme.secondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (avatarUrl != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: isSaving ? null : onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: AppTheme.error,
              size: 18,
            ),
            label: const Text(
              "Supprimer l'avatar",
              style: TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
