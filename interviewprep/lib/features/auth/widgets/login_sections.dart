import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';

class LoginSuccessOverlay extends StatelessWidget {
  const LoginSuccessOverlay({required this.visible, super.key});
  final bool visible;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    child: visible
        ? Container(
            key: const ValueKey('success_overlay'),
            color: Colors.white.withAlpha((0.9 * 255).round()),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connexion réussie...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink(key: ValueKey('empty')),
  );
}

class LoginInsightsCard extends StatelessWidget {
  const LoginInsightsCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppTheme.primaryContainer, AppTheme.secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: AppTheme.secondaryColor.withValues(alpha: 0.3),
          blurRadius: 15,
        ),
      ],
    ),
    padding: const EdgeInsets.all(24),
    child: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'AI INSIGHTS',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Master your next interview.',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Join 50k+ professionals using our proprietary AI simulation engine to land top-tier roles.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        Positioned(
          right: -20,
          bottom: -20,
          child: Icon(
            Icons.psychology,
            size: 100,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ],
    ),
  );
}

class LoginNavigationLink extends StatelessWidget {
  const LoginNavigationLink({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Don't have an account?",
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
      ),
      TextButton(
        onPressed: () => context.go('/register'),
        child: Text(
          'Create Account',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppTheme.secondaryColor),
        ),
      ),
    ],
  );
}
