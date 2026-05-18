import 'package:flutter/material.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercices Pratiques'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildExerciseCard(
            context,
            title: 'QCM Algorithmique',
            description: 'Testez vos connaissances en structures de données.',
            icon: Icons.code,
          ),
          _buildExerciseCard(
            context,
            title: 'Test de Logique',
            description: 'Résolvez des problèmes de logique pour vous échauffer.',
            icon: Icons.psychology,
          ),
          _buildExerciseCard(
            context,
            title: 'Étude de cas RH',
            description: 'Comment réagiriez-vous dans des situations conflictuelles ?',
            icon: Icons.people,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, {required String title, required String description, required IconData icon}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          child: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(description),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Naviguer vers le détail de l'exercice
        },
      ),
    );
  }
}
