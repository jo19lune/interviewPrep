import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class QaModuleContainer extends StatelessWidget {
  final Widget child;
  final String? title;

  const QaModuleContainer({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (title != null) const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
