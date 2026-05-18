import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('À propos'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/mon_logo.png',
              height: 100,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.work,
                size: 100,
                color: Color(0xFF001A5E),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'InterviewPrep',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 8),
            const Text('Version 1.0.0'),
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
