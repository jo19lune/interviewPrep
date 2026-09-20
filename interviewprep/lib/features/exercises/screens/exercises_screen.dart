import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/exercise_models.dart';
import '../providers/exercise_provider.dart';
import '../widgets/exercise_widgets.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exercisesListProvider);
    final filters = ref.watch(exerciseFiltersProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Exercices de préparation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Générer un exercice',
            onPressed: () => _generateExercise(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(exercisesListProvider),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 16),
            ExerciseFilters(
              filters: filters,
              onDomainChanged: (value) =>
                  ref.read(exerciseFiltersProvider.notifier).setDomaine(value),
              onDifficultyChanged: (value) => ref
                  .read(exerciseFiltersProvider.notifier)
                  .setDifficulte(value),
            ),
            const SizedBox(height: 20),
            exercises.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Erreur: $error'),
              data: (items) {
                final filtered = items.where(_matches).toList();
                if (filtered.isEmpty) {
                  return const EmptyExercises();
                }
                return Column(
                  children: filtered
                      .map(
                        (exercise) => ExerciseCard(
                          exercise: exercise,
                          onTap: () => _showModes(context, exercise),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _matches(ExerciceResponse exercise) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return exercise.titre.toLowerCase().contains(query) ||
        (exercise.description?.toLowerCase().contains(query) ?? false) ||
        exercise.domaine.toLowerCase().contains(query);
  }

  Future<void> _generateExercise(BuildContext context) async {
    final generated = await showModalBottomSheet<ExerciceResponse>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ExerciseGenerationSheet(),
    );
    if (generated != null && context.mounted) _showModes(context, generated);
  }

  void _showModes(BuildContext context, ExerciceResponse exercise) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ExerciseModeSheet(
        exercise: exercise,
        onSimulation: () {
          ref.read(selectedExerciseProvider.notifier).select(exercise);
          Navigator.pop(context);
          context.go('/simulation');
        },
        onQa: () {
          Navigator.pop(context);
          context.go(
            '/exercises/qa?exerciseId=${Uri.encodeComponent(exercise.id)}'
            '&exerciseTitle=${Uri.encodeComponent(exercise.titre)}'
            '&domaine=${Uri.encodeComponent(exercise.domaine)}'
            '&difficulte=${Uri.encodeComponent(exercise.difficulte)}',
          );
        },
      ),
    );
  }
}
