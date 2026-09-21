import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/exercise_models.dart';
import '../../../app/theme/app_theme.dart';
import '../providers/exercise_provider.dart' as exercise_provider;

const _domains = [
  'Tous',
  'TECHNIQUE',
  'COMPORTEMENTAL',
  'SITUATIONNEL',
  'ETUDE_DE_CAS',
  'MOTIVATION',
];
const _difficulties = ['Tous', 'DEBUTANT', 'INTERMEDIAIRE', 'AVANCE'];

class ExerciseFilters extends StatelessWidget {
  const ExerciseFilters({
    super.key,
    required this.filters,
    required this.onDomainChanged,
    required this.onDifficultyChanged,
  });

  final exercise_provider.ExerciseFilters filters;
  final ValueChanged<String?> onDomainChanged;
  final ValueChanged<String?> onDifficultyChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: [
        DropdownButton<String>(
          value: filters.domaine ?? 'Tous',
          items: _domains
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onDomainChanged,
        ),
        DropdownButton<String>(
          value: filters.difficulte ?? 'Tous',
          items: _difficulties
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onDifficultyChanged,
        ),
      ],
    );
  }
}

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({super.key, required this.exercise, required this.onTap});

  final ExerciceResponse exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.quiz, color: AppTheme.secondaryColor),
        title: Text(exercise.titre),
        subtitle: Text('${exercise.domaine} · ${exercise.difficulte}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class EmptyExercises extends StatelessWidget {
  const EmptyExercises({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: Text('Aucun exercice trouvé.')),
    );
  }
}

class ExerciseModeSheet extends StatelessWidget {
  const ExerciseModeSheet({
    super.key,
    required this.exercise,
    required this.onSimulation,
    required this.onQa,
  });

  final ExerciceResponse exercise;
  final VoidCallback onSimulation;
  final VoidCallback onQa;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(exercise.titre, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onSimulation,
            icon: const Icon(Icons.mic),
            label: const Text('Mode Entretien IA'),
          ),
          OutlinedButton.icon(
            onPressed: onQa,
            icon: const Icon(Icons.edit_note),
            label: const Text('Mode Écrit (Q&A)'),
          ),
        ],
      ),
    );
  }
}

class ExerciseGenerationSheet extends ConsumerStatefulWidget {
  const ExerciseGenerationSheet({super.key});

  @override
  ConsumerState<ExerciseGenerationSheet> createState() =>
      _ExerciseGenerationSheetState();
}

class _ExerciseGenerationSheetState
    extends ConsumerState<ExerciseGenerationSheet> {
  String _domain = 'TECHNIQUE';
  String _difficulty = 'DEBUTANT';
  final _subject = TextEditingController();

  @override
  void dispose() {
    _subject.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(exerciseGenerationProvider).isLoading;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _domain,
            items: _domains
                .skip(1)
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => _domain = value!),
            decoration: const InputDecoration(labelText: 'Domaine'),
          ),
          DropdownButtonFormField<String>(
            value: _difficulty,
            items: _difficulties
                .skip(1)
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => _difficulty = value!),
            decoration: const InputDecoration(labelText: 'Difficulté'),
          ),
          TextField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Sujet'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: loading ? null : _generate,
            child: Text(loading ? 'Génération...' : 'Générer'),
          ),
        ],
      ),
    );
  }

  Future<void> _generate() async {
    try {
      final result = await ref
          .read(exerciseGenerationProvider.notifier)
          .generate(
            domaine: _domain,
            difficulte: _difficulty,
            sujet: _subject.text.trim().isEmpty ? null : _subject.text.trim(),
          );
      if (mounted) Navigator.pop(context, result);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $error')));
      }
    }
  }
}
