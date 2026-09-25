import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class AuthPageFrame extends StatelessWidget {
  const AuthPageFrame({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: child,
        ),
      ),
    ),
  );
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({required this.title, required this.subtitle, super.key});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Image.asset(
        'assets/icon/logo.png',
        height: 100,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.work, size: 80, color: AppTheme.primaryContainer),
      ),
      const SizedBox(height: 24),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.displayMedium?.copyWith(color: AppTheme.primaryContainer),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 32),
    ],
  );
}

class AuthCard extends StatelessWidget {
  const AuthCard({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryContainer.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.all(24),
    child: child,
  );
}

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    required this.loading,
    required this.onPressed,
    required this.label,
    this.icon,
    super.key,
  });
  final bool loading;
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon ?? Icons.arrow_forward),
          label: Text(label),
        ),
      ),
      const SizedBox(height: 24),
    ],
  );
}
