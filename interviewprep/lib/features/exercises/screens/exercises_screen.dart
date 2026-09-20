import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/exercise_provider.dart';
import '../../../core/models/exercise_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showGenerateExerciseBottomSheet(BuildContext context) async {
    final generated = await showModalBottomSheet<ExerciceResponse>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return _GenerateExerciseSheet();
      },
    );
    if (generated != null && context.mounted) {
      _showModeBottomSheet(context, ref, generated);
    }
  }

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
      case 'MOTIVATION':
        return AppTheme.secondaryContainer.withAlpha((0.1 * 255).round());
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
      case 'MOTIVATION':
        return AppTheme.onSecondaryContainer;
      default:
        return AppTheme.onSurfaceVariant;
    }
  }

  String _domainToFrench(String? domaine) {
    switch (domaine?.toUpperCase()) {
      case 'TECHNIQUE':
        return 'Technique';
      case 'COMPORTEMENTAL':
        return 'Comportemental';
      case 'SITUATIONNEL':
        return 'Situations';
      case 'ETUDE_DE_CAS':
        return '\u00c9tudes de cas';
      case 'MOTIVATION':
        return 'Motivation';
      default:
        return domaine ?? 'Aucune donn\u00e9e';
    }
  }

  Map<String, dynamic>? _getTopSkillEntry(Map<String, dynamic> stats) {
    final entries = stats.entries
        .where((e) => e.value is Map && (e.value as Map).containsKey('avg_score'))
        .toList();
    entries.sort((a, b) {
      final aScore = ((a.value as Map)['avg_score'] as num?) ?? 0;
      final bScore = ((b.value as Map)['avg_score'] as num?) ?? 0;
      return bScore.compareTo(aScore);
    });
    if (entries.isNotEmpty) {
      return {
        'key': entries.first.key,
        'avg': ((entries.first.value as Map)['avg_score'] as num?)?.toDouble() ?? 0.0,
      };
    }
    return null;
  }

  List<ExerciceResponse> _filterExercises(List<ExerciceResponse> exercises) {
    if (_searchQuery.isEmpty) return exercises;
    final q = _searchQuery.toLowerCase();
    return exercises.where((ex) {
      return ex.titre.toLowerCase().contains(q) ||
          (ex.description?.toLowerCase().contains(q) ?? false) ||
          ex.domaine.toLowerCase().contains(q) ||
          ex.difficulte.toLowerCase().contains(q);
    }).toList();
  }

  void _showModeBottomSheet(
    BuildContext context,
    WidgetRef ref,
    ExerciceResponse exercise,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Titre et domaine
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getColorForDomaine(exercise.domaine),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForDomaine(exercise.domaine),
                      color: _getIconColorForDomaine(exercise.domaine),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.titre,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: AppTheme.primaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryContainer.withAlpha(
                                  (0.08 * 255).round(),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                exercise.difficulte,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _domainToFrench(exercise.domaine),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if ((exercise.description ?? '').isNotEmpty) ...[
                Text(
                  exercise.description ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'Choisissez votre mode d\'entraînement',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.primaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Mode Simulation IA
              _ModeCard(
                icon: Icons.mic,
                iconColor: Colors.white,
                iconBgColor: AppTheme.primaryContainer,
                title: 'Mode Entretien IA',
                subtitle:
                    'Répondez à voix ou par écrit à un recruteur virtuel IA. Obtenez un bilan personnalisé à la fin.',
                badge: 'Recommandé',
                badgeColor: AppTheme.tertiaryFixed,
                badgeTextColor: AppTheme.onTertiaryFixedVariant,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ref.read(selectedExerciseProvider.notifier).select(exercise);
                  context.go('/simulation');
                },
              ),
              const SizedBox(height: 12),
              // Mode Écrit Q&A
              _ModeCard(
                icon: Icons.edit_note,
                iconColor: AppTheme.onSecondaryContainer,
                iconBgColor: AppTheme.secondaryContainer,
                title: 'Mode Écrit (Q&A)',
                subtitle:
                    'Entraînez-vous par questions-réponses écrites avec l\'IA. Idéal pour préparer vos réponses.',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.go(
                    '/exercises/qa?exerciseId=${Uri.encodeComponent(exercise.id)}'
                    '&exerciseTitle=${Uri.encodeComponent(exercise.titre)}'
                    '&domaine=${Uri.encodeComponent(exercise.domaine)}'
                    '&difficulte=${Uri.encodeComponent(exercise.difficulte)}',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesListProvider);
    final filters = ref.watch(exerciseFiltersProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final progressAsync = ref.watch(userProgressProvider);
    final statsAsync = ref.watch(detailedStatsProvider);

    final List<String> domaines = [
      'Tous',
      'TECHNIQUE',
      'COMPORTEMENTAL',
      'SITUATIONNEL',
      'ETUDE_DE_CAS',
      'MOTIVATION',
    ];

    String? prenom;
    if (profileAsync.hasValue) {
      prenom = profileAsync.value!.prenom;
    }
    double? readinessScore;
    String? topSkill;
    String? recommendationTitle;
    String? recommendationSub;
    if (progressAsync.hasValue) {
      final p = progressAsync.value!;
      readinessScore = p.bestScore;
      if (statsAsync.hasValue) {
        final topEntry = _getTopSkillEntry(statsAsync.value!);
        if (topEntry != null) {
          topSkill = topEntry['key'] as String;
          final avg = topEntry['avg'] as double;
          if (avg >= 80 && p.totalSessions >= 3) {
            recommendationTitle = 'Excellents r\u00e9sultats';
            recommendationSub =
                'Votre score moyen est exceptionnel. Essayez des cas de niveau Expert pour repousser vos limites.';
          } else if (avg >= 60) {
            recommendationTitle = 'Bonne progression';
            recommendationSub =
                'Continuez d\'ajouter des chiffres pr\u00e9cis et des indicateurs de succ\u00e8s (KPI) dans vos \u00e9tudes de cas.';
          } else {
            recommendationTitle = 'Am\u00e9liorer la clart\u00e9';
            recommendationSub =
                'Essayez de d\u00e9tailler davantage vos explications en utilisant des termes pr\u00e9cis.';
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        shadowColor: Colors.black.withAlpha((0.05 * 255).round()),
        title: Text(
          'Exercices de pr\u00e9paration',
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
              'Perfectionnez vos comp\u00e9tences',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppTheme.primaryContainer,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'S\u00e9lectionnez un exercice pour choisir votre mode d\'entraînement.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            // Hero Card IA
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryContainer.withAlpha(
                      (0.12 * 255).round(),
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                    prenom != null ? 'Welcome back, $prenom' : 'Welcome back',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (topSkill != null)
                    Text(
                      'Votre domaine le plus fort : ${_domainToFrench(topSkill)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withAlpha((0.9 * 255).round()),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Taux de pr\u00e9paration : ${readinessScore?.round() ?? 0}%',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withAlpha((0.9 * 255).round()),
                    ),
                  ),
                  if (recommendationTitle != null &&
                      recommendationSub != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      '$recommendationTitle\u00a0: $recommendationSub',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withAlpha((0.88 * 255).round()),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/simulation'),
                    icon: const Icon(
                      Icons.play_arrow,
                      color: AppTheme.primaryContainer,
                    ),
                    label: const Text(
                      'Start Module',
                      style: TextStyle(
                        color: AppTheme.primaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryContainer,
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 22,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Champ de recherche FONCTIONNEL
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un exercice...',
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: AppTheme.outline),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.outline),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SmallMetricCard(
                    icon: Icons.trending_up,
                    label: 'Readiness',
                    value: '${readinessScore?.round() ?? 0}%',
                    color: AppTheme.secondaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SmallMetricCard(
                    icon: Icons.lightbulb,
                    label: 'Top Skill',
                    value: _domainToFrench(topSkill),
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
                    child: const Icon(
                      Icons.trending_up,
                      color: AppTheme.onSecondaryContainer,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${readinessScore?.round() ?? 0}% Readiness',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: AppTheme.primaryContainer,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          prenom != null
                              ? '$prenom, continuez sur cette lanc\u00e9e avec des exercices cibl\u00e9s.'
                              : 'Continuez sur cette lanc\u00e9e avec des exercices cibl\u00e9s.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.onSurfaceVariant),
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
              'Filtrer par domaine\u00a0:',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: domaines.map((domaine) {
                  final bool isSelected =
                      (domaine == 'Tous' && filters.domaine == null) ||
                      (filters.domaine == domaine);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(domaine),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          ref
                              .read(exerciseFiltersProvider.notifier)
                              .setDomaine(domaine);
                          // Réinitialise la recherche si on change de filtre
                          if (_searchQuery.isNotEmpty) {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          }
                        }
                      },
                      selectedColor: AppTheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.onSurfaceVariant,
                      ),
                      backgroundColor: AppTheme.surfaceContainerLowest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Liste des exercices avec filtre de recherche appliqué
            exercisesAsync.when(
              data: (exercises) {
                final filtered = _filterExercises(exercises);
                if (filtered.isEmpty) {
                  return Card(
                    color: AppTheme.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off
                                : Icons.search_off,
                            size: 64,
                            color: AppTheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Aucun résultat pour "$_searchQuery"'
                                : 'Aucun exercice disponible',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Modifiez votre recherche ou changez de filtre.'
                                : 'Essayez de modifier vos filtres ou tirez vers le bas pour actualiser.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.outline),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          '${filtered.length} résultat${filtered.length > 1 ? 's' : ''} pour "$_searchQuery"',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                      ),
                    ...filtered.map((exercise) {
                      return _buildExerciseCard(
                        context,
                        ref,
                        exercise: exercise,
                      );
                    }),
                  ],
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
                  child: Text(
                    'Erreur lors du chargement\u00a0: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGenerateExerciseBottomSheet(context),
        label: const Text(
          'G\u00e9n\u00e9rer avec l\'IA',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.auto_awesome),
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    WidgetRef ref, {
    required ExerciceResponse exercise,
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
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showModeBottomSheet(context, ref, exercise),
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
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontSize: 18,
                              color: AppTheme.primaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        exercise.description ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer.withAlpha(
                                (0.06 * 255).round(),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exercise.difficulte,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppTheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$minutes min',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.touch_app,
                            size: 14,
                            color: AppTheme.secondaryColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Choisir le mode',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.secondaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.outlineVariant,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Widgets auxiliaires ───────────────────

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppTheme.primaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor ?? AppTheme.tertiaryFixed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    badgeTextColor ??
                                    AppTheme.onTertiaryFixedVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.outlineVariant),
            ],
          ),
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
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenerateExerciseSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_GenerateExerciseSheet> createState() =>
      _GenerateExerciseSheetState();
}

class _GenerateExerciseSheetState
    extends ConsumerState<_GenerateExerciseSheet>
    with SingleTickerProviderStateMixin {
  String _selectedDomaine = 'TECHNIQUE';
  String _selectedNiveau = 'DEBUTANT';
  final _sujetController = TextEditingController();
  int _nombreQuestions = 10;
  bool _isGenerating = false;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Estimation de la durée max
    );
  }

  @override
  void dispose() {
    _sujetController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.secondaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'G\u00e9n\u00e9rer un Exercice IA',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.primaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'L\'intelligence artificielle va concevoir des questions personnalis\u00e9es adapt\u00e9es \u00e0 vos besoins.',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // Dropdown Domaine
              DropdownButtonFormField<String>(
                initialValue: _selectedDomaine,
                decoration: const InputDecoration(
                  labelText: 'Domaine de comp\u00e9tences',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                dropdownColor: AppTheme.surfaceContainerLowest,
                items: const [
                  DropdownMenuItem(
                    value: 'TECHNIQUE',
                    child: Text('Technique'),
                  ),
                  DropdownMenuItem(
                    value: 'COMPORTEMENTAL',
                    child: Text('Comportemental'),
                  ),
                  DropdownMenuItem(
                    value: 'SITUATIONNEL',
                    child: Text('Situationnel'),
                  ),
                  DropdownMenuItem(
                    value: 'ETUDE_DE_CAS',
                    child: Text('\u00c9tude de cas'),
                  ),
                  DropdownMenuItem(
                    value: 'MOTIVATION',
                    child: Text('Motivation'),
                  ),
                ],
                onChanged: _isGenerating
                    ? null
                    : (val) => setState(() => _selectedDomaine = val!),
              ),
              const SizedBox(height: 16),

              // Dropdown Niveau
              DropdownButtonFormField<String>(
                initialValue: _selectedNiveau,
                decoration: const InputDecoration(
                  labelText: 'Niveau de difficult\u00e9',
                  prefixIcon: Icon(Icons.trending_up_outlined),
                ),
                dropdownColor: AppTheme.surfaceContainerLowest,
                items: const [
                  DropdownMenuItem(
                    value: 'DEBUTANT',
                    child: Text('D\u00e9butant'),
                  ),
                  DropdownMenuItem(
                    value: 'INTERMEDIAIRE',
                    child: Text('Interm\u00e9diaire'),
                  ),
                  DropdownMenuItem(value: 'AVANCE', child: Text('Avanc\u00e9')),
                  DropdownMenuItem(value: 'EXPERT', child: Text('Expert')),
                ],
                onChanged: _isGenerating
                    ? null
                    : (val) => setState(() => _selectedNiveau = val!),
              ),
              const SizedBox(height: 16),

              // TextField Sujet
              TextField(
                controller: _sujetController,
                enabled: !_isGenerating,
                style: const TextStyle(color: AppTheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Sujet ou Focus sp\u00e9cifique (Optionnel)',
                  hintText:
                      'Ex: React Hooks, N\u00e9gociation B2B, Gestion Agile...',
                  prefixIcon: const Icon(Icons.lightbulb_outline),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Questions Count Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nombre de questions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryContainer,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$_nombreQuestions',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _nombreQuestions.toDouble(),
                min: 5,
                max: 25,
                divisions: 4,
                label: '$_nombreQuestions questions',
                onChanged: _isGenerating
                    ? null
                    : (val) {
                        setState(() => _nombreQuestions = val.round());
                      },
              ),
              const SizedBox(height: 24),

              // Button Generate
              if (_isGenerating)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressController.value,
                          backgroundColor: AppTheme.surfaceContainerLow,
                          color: AppTheme.secondaryColor,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Création de l\'exercice en cours...',
                      style: TextStyle(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _generate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text(
                      'Générer l\'exercice',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    _progressController.forward(from: 0.0);
    try {
      final generatedExercise = await ref
          .read(exerciseGenerationProvider.notifier)
          .generate(
            domaine: _selectedDomaine,
            difficulte: _selectedNiveau,
            sujet: _sujetController.text,
            nombreQuestions: _nombreQuestions,
          );

      _progressController.value = 1.0;
      await Future.delayed(const Duration(milliseconds: 300)); // Laisse le temps de voir la barre pleine

      if (mounted) {
        Navigator.pop(
          context,
          generatedExercise,
        ); // Return exercise to open sheet
      }
    } catch (e) {
      _progressController.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la g\u00e9n\u00e9ration: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}
