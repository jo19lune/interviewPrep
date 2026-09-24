import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _navigateTo(String route, BuildContext context) {
    if (ModalRoute.of(context)?.settings.name != route) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('À propos'),
        backgroundColor: AppTheme.surface,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppTheme.primaryContainer),
              child: Center(
                child: Text(
                  'InterviewPrep',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Tableau de bord'),
              onTap: () => _navigateTo('/dashboard', context),
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Exercices'),
              onTap: () => _navigateTo('/exercises', context),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Statistiques'),
              onTap: () => _navigateTo('/dashboard/statistics', context),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('À propos'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '© 2026 Projet d\'Étude\nTous droits réservés.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
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
            const Text('Version 2.0.0'),
            const SizedBox(height: 32),
            const Text(
              'Application développée pour vous aider à réussir vos entretiens d\'embauche avec l\'aide de l\'IA et d\'exercices pratiques ciblés.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const Spacer(),
            const Text(
              '© 2026 Projet d\'Étude - InterviewPrep\nTous droits réservés.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
