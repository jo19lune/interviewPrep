import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import 'standalone_qa_intro_settings.dart';

class StandaloneQAIntro extends StatelessWidget {
  const StandaloneQAIntro({
    super.key,
    required this.title,
    required this.domaine,
    required this.difficulte,
    required this.subjectController,
    required this.questionCount,
    required this.isStarting,
    required this.onQuestionCountChanged,
    required this.onStart,
  });
  final String? title, domaine, difficulte;
  final TextEditingController subjectController;
  final int questionCount;
  final bool isStarting;
  final ValueChanged<int> onQuestionCountChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.secondaryContainer, AppTheme.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryContainer.withAlpha(
                  (0.15 * 255).round(),
                ),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.edit_note, color: Colors.white, size: 40),
              const SizedBox(height: 16),
              Text(
                title ?? 'Mode Questions-Réponses',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Entraînez-vous avec un assistant IA qui vous posera des questions et évaluera vos réponses en temps réel.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha((0.9 * 255).round()),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (domaine != null) _Chip('Domaine', domaine!),
                  if (difficulte != null) _Chip('Difficulté', difficulte!),
                  const _Chip('Mode', 'Écrit'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        StandaloneQAIntroSettings(
          controller: subjectController,
          questionCount: questionCount,
          isStarting: isStarting,
          onQuestionCountChanged: onQuestionCountChanged,
          onStart: onStart,
        ),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.surface.withAlpha((0.2 * 255).round()),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withAlpha((0.3 * 255).round())),
    ),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}
