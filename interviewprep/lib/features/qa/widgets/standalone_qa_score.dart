import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../services/qa_service.dart';

class StandaloneQAScore extends StatelessWidget {
  const StandaloneQAScore({super.key, required this.feedback});
  final QAFeedback feedback;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: AppTheme.primaryContainer,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        const Text(
          'VOTRE SCORE GLOBAL',
          style: TextStyle(
            color: AppTheme.primaryFixedVariant,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 130,
              height: 130,
              child: CircularProgressIndicator(
                value: feedback.scoreGlobal / 100,
                strokeWidth: 12,
                backgroundColor: Colors.white.withAlpha((0.15 * 255).round()),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.tertiaryFixed,
                ),
              ),
            ),
            Text(
              '${feedback.scoreGlobal.round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          feedback.scoreGlobal >= 70
              ? '🎉 Excellent travail !'
              : feedback.scoreGlobal >= 50
              ? '👍 Bonne progression'
              : '💪 Continuez vos efforts',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
