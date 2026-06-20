import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class QaChatBubble extends StatelessWidget {
  final String messageId;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final double? scorePartiel;
  final String? sentiment;
  final String? coachingTip;
  final Map<String, dynamic>? analysis;

  const QaChatBubble({
    super.key,
    required this.messageId,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.scorePartiel,
    this.sentiment,
    this.coachingTip,
    this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUserMsg = isUser;

    return Align(
      alignment: isUserMsg ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUserMsg ? const Color(0xFF1E293B) : AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16).copyWith(
            topRight: isUserMsg ? const Radius.circular(4) : null,
            topLeft: !isUserMsg ? const Radius.circular(4) : null,
          ),
          border: Border.all(
            color: isUserMsg
                ? const Color(0xFF1E293B).withAlpha((0.2 * 255).round())
                : AppTheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isUserMsg ? Colors.white : AppTheme.onSurface,
                height: 1.4,
              ),
            ),
            if (coachingTip != null && coachingTip!.isNotEmpty && !isUserMsg) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 14, color: AppTheme.secondaryColor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        coachingTip!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSecondaryContainer,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatTime(timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isUserMsg
                    ? Colors.white.withAlpha((0.7 * 255).round())
                    : AppTheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return "À l'instant";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min";
    return "${diff.inHours}h${diff.inMinutes.toString().padLeft(2, '0')}";
  }
}
