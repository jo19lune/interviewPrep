import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ProfileAppBar({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppBar(
    backgroundColor: AppTheme.surface,
    elevation: 1,
    title: const Text(
      'Mon Profil',
      style: TextStyle(
        color: AppTheme.primaryContainer,
        fontWeight: FontWeight.bold,
      ),
    ),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: AppTheme.primaryContainer),
      onPressed: () => context.pop(),
    ),
    actions: [
      TextButton.icon(
        onPressed: () async {
          await ref.read(authStateProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        },
        icon: const Icon(Icons.logout, color: AppTheme.error, size: 18),
        label: const Text(
          'Déconnexion',
          style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(width: 8),
    ],
  );
}
