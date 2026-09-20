import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.large = false,
    super.key,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: large ? 260 : 140,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryContainer.withAlpha((0.04 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha((0.16 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppTheme.primaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: large ? 22 : 20,
            ),
          ),
        ],
      ),
    ),
  );
}

class InsightCard extends StatelessWidget {
  const InsightCard({
    required this.title,
    required this.description,
    this.onPractice,
    super.key,
  });
  final String title;
  final String description;
  final VoidCallback? onPractice;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppTheme.primaryContainer,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'AI Insight'.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withAlpha((0.88 * 255).round()),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onPractice,
          icon: const Icon(Icons.play_arrow, size: 18),
          label: const Text(
            'Démarrer une pratique suggérée',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surfaceContainerLowest,
            foregroundColor: AppTheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ],
    ),
  );
}
