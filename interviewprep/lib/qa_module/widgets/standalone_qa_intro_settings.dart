import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StandaloneQAIntroSettings extends StatelessWidget {
  const StandaloneQAIntroSettings({
    super.key,
    required this.controller,
    required this.questionCount,
    required this.isStarting,
    required this.onQuestionCountChanged,
    required this.onStart,
  });
  final TextEditingController controller;
  final int questionCount;
  final bool isStarting;
  final ValueChanged<int> onQuestionCountChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paramétrer la session',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.primaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Sujet ou domaine cible (optionnel)',
                hintText: 'Ex: Flutter, data science, marketing...',
                prefixIcon: const Icon(Icons.topic_outlined),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nombre de questions',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryContainer,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$questionCount questions',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: questionCount.toDouble(),
              min: 5,
              max: 20,
              divisions: 15,
              label: '$questionCount',
              activeColor: AppTheme.secondaryColor,
              onChanged: (value) => onQuestionCountChanged(value.round()),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.secondaryContainer.withAlpha((0.2 * 255).round()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.secondaryContainer.withAlpha((0.4 * 255).round()),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppTheme.secondaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'L\'IA vous posera des questions adaptées, évaluera chaque réponse et générera un bilan détaillé à la fin de la session.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 32),
      SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          onPressed: isStarting ? null : onStart,
          icon: isStarting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.play_arrow, color: Colors.white),
          label: Text(
            isStarting ? 'Démarrage...' : 'Démarrer la session',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    ],
  );
}
