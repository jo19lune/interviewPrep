class _MiniBadge extends StatelessWidget {
  final String label;
  final String value;

  const _MiniBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryContainer,
              ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final String value;

  const _ScoreChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: AppTheme.onSecondaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha((0.2 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
