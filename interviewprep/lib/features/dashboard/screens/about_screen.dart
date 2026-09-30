import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// À synchroniser avec `version:` dans `pubspec.yaml` (2.1.3) et avec
  /// `APP_VERSION` côté backend. Cette constante est la seule chose que
  /// l'utilisateur voit du numéro de version : elle avait dérivé jusqu'à
  /// 2.0.1 pendant que les tags atteignaient 2.1.2.
  static const String appVersion = '2.1.3';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        title: const Text(
          'À propos',
          style: TextStyle(
            color: AppTheme.primaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryContainer),
          onPressed: () => context.pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 700 ? 96.0 : 24.0;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icon/logo.png',
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.work,
                      size: 100,
                      color: AppTheme.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'InterviewPrep',
                    style: Theme.of(
                      context,
                    ).textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version $appVersion',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Application développée pour vous aider à réussir vos entretiens d\'embauche avec l\'aide de l\'IA et d\'exercices pratiques ciblés.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  const _FeatureTile(
                    icon: Icons.mic,
                    title: 'Simulations d\'entretien',
                    subtitle:
                        'Entraînez-vous sur des scénarios réalistes avec un coach IA.',
                  ),
                  const _FeatureTile(
                    icon: Icons.quiz,
                    title: 'Exercices ciblés',
                    subtitle:
                        'Des questions adaptées à votre domaine et à votre niveau.',
                  ),
                  const _FeatureTile(
                    icon: Icons.insights,
                    title: 'Suivi de progression',
                    subtitle:
                        'Analysez vos résultats et visualisez vos progrès dans le temps.',
                  ),
                  const SizedBox(height: 40),
                  Text(
                    '© 2026 Projet d\'Étude - InterviewPrep\nTous droits réservés.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryContainer,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
