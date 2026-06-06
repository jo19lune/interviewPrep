import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bottom_navigation.dart';
import '../providers/exercise_provider.dart';
import '../../../core/models/exercise.dart' as models;

class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  IconData _getIconForDomaine(String domaine) {
    switch (domaine.toUpperCase()) {
      case 'TECHNIQUE':
        return Icons.code;
      case 'COMPORTEMENTAL':
        return Icons.record_voice_over;
      case 'SITUATIONNEL':
        return Icons.people;
      case 'ETUDE_DE_CAS':
        return Icons.business_center;
      case 'MOTIVATION':
        return Icons.emoji_objects;
      default:
        return Icons.quiz;
    }
  }

  Color _getColorForDomaine(String domaine) {
    switch (domaine.toUpperCase()) {
      case 'TECHNIQUE':
        return AppTheme.secondaryContainer;
      case 'COMPORTEMENTAL':
        return AppTheme.tertiaryFixed;
      case 'SITUATIONNEL':
        return AppTheme.primaryContainer.withAlpha((0.1 * 255).round());
      case 'ETUDE_DE_CAS':
        return Colors.orange.withAlpha((0.15 * 255).round());
      default:
        return AppTheme.surfaceContainerLow;
    }
  }

  Color _getIconColorForDomaine(String domaine) {
    switch (domaine.toUpperCase()) {
      case 'TECHNIQUE':
        return AppTheme.onSecondaryContainer;
      case 'COMPORTEMENTAL':
        return AppTheme.onTertiaryFixedVariant;
      case 'SITUATIONNEL':
        return AppTheme.primaryContainer;
      case 'ETUDE_DE_CAS':
        return Colors.orange[800]!;
      default:
        return AppTheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesListProvider);
    final filters = ref.watch(exerciseFiltersProvider);

    final List<String> domaines = ['Tous', 'TECHNIQUE', 'COMPORTEMENTAL', 'SITUATIONNEL', 'ETUDE_DE_CAS'];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        shadowColor: Colors.black.withAlpha((0.05 * 255).round()),
        title: Text(
          'Exercices de préparation',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(exercisesListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            Text(
              'Perfectionnez vos compétences',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.primaryContainer,
                    fontSize: 26,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez un exercice pour lancer une simulation avec notre recruteur virtuel IA.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryContainer.withAlpha((0.12 * 255).round()),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'AI Recommended',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Master the "Behavioral Edge"',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Based on your recent performance, focus on STAR storytelling and confidence under pressure.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withAlpha((0.88 * 255).round()),
                        ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/simulation'),
                    icon: const Icon(Icons.play_arrow, color: AppTheme.primaryContainer),
                    label: const Text('Start Module', style: TextStyle(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un exercice',
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: AppTheme.outline),
                contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
              ),
              readOnly: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recherche visuelle à venir')), 
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SmallMetricCard(
                    icon: Icons.trending_up,
                    label: 'Readiness',
                    value: '84%',
                    color: AppTheme.secondaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SmallMetricCard(
                    icon: Icons.lightbulb,
                    label: 'Top Skill',
                    value: 'Storytelling',
                    color: AppTheme.primaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.outlineVariant),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.trending_up, color: AppTheme.onSecondaryContainer, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '84% Readiness',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: AppTheme.primaryContainer,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You’ve completed 12 modules this week. Keep the momentum going with targeted exercises.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Filtres thématiques
            Text(
              'Filtrer par domaine :',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: domaines.map((domaine) {
                  final bool isSelected = (domaine == 'Tous' && filters.domaine == null) ||
                                          (filters.domaine == domaine);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(domaine),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(exerciseFiltersProvider.notifier).setDomaine(domaine);
                        }
                      },
                      selectedColor: AppTheme.primaryContainer,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.onSurfaceVariant),
                      backgroundColor: AppTheme.surfaceContainerLowest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
            
            // Liste des exercices
            exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Card(
                    color: AppTheme.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 64, color: AppTheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun exercice disponible',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Essayez de modifier vos filtres ou tirez vers le bas pour actualiser.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.outline),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: exercises.map((exercise) {
                    return _buildExerciseCard(
                      context,
                      ref,
                      exercise: exercise,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Erreur lors du chargement: $err', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNavigation(),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    WidgetRef ref, {
    required models.Exercise exercise,
  }) {
    final String domaine = exercise.domaine;
    final IconData icon = _getIconForDomaine(domaine);
    final Color bgColor = _getColorForDomaine(domaine);
    final Color iconColor = _getIconColorForDomaine(domaine);
    
    final int minutes = exercise.dureeSec ~/ 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryContainer.withAlpha((0.03 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ref.read(selectedExerciseProvider.notifier).state = exercise;
            context.go('/simulation');
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.titre, 
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 18, color: AppTheme.primaryContainer, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 6),
                      Text(
                        exercise.description ?? '', 
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant, fontSize: 14)
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer.withAlpha((0.06 * 255).round()),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exercise.difficulte,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: AppTheme.outline),
                              const SizedBox(width: 4),
                              Text('$minutes min', style: const TextStyle(fontSize: 12, color: AppTheme.outline)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Align(
                  alignment: Alignment.center,
                  child: Icon(Icons.arrow_forward_ios, color: AppTheme.outlineVariant, size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Removed unused bottom navigation builder; app uses shared bottom navigation widget.

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppTheme.onSecondaryContainer : AppTheme.onSurfaceVariant),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? AppTheme.onSecondaryContainer : AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SmallMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha((0.18 * 255).round()),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryContainer)),
            ],
          ),
        ],
      ),
    );
  }
}
