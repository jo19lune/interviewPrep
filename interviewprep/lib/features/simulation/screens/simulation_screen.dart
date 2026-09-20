import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../exercises/providers/exercise_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/simulation_provider.dart';
import '../../../core/models/exercise_models.dart';
import '../../../qa_module/models/chat_message.dart';

class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({super.key});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _subjectController = TextEditingController();
  final _scrollController = ScrollController();
  int _questionCount = 10;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _subjectController.dispose();
    _scrollController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendAnswer(SimulationNotifier notifier) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    try {
      await notifier.sendAnswer(text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _cancelSimulation(SimulationNotifier notifier) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la simulation ?'),
        content: const Text('La session sera marquee comme annulee et aucun bilan ne sera genere.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuer'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    if (shouldCancel != true) return;

    try {
      await notifier.cancel();
      if (mounted) {
        context.go('/exercises');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = ref.watch(selectedExerciseProvider);
    final state = ref.watch(simulationProvider);
    final notifier = ref.read(simulationProvider.notifier);

    // Si aucun exercice n'est sélectionné, inviter à en choisir un
    if (exercise == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          title: const Text('Simulation'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 64, color: AppTheme.secondaryColor),
                const SizedBox(height: 16),
                Text(
                  'Aucun exercice sélectionné',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 20, color: AppTheme.primaryContainer),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sélectionnez d\'abord un exercice dans la liste pour commencer l\'entretien.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.outline),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/exercises'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sélectionner un exercice'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Affichage des différents écrans selon l'état de la simulation
    if (state.feedback != null) {
      return _buildFeedbackScreen(context, state, notifier);
    }

    if (state.sessionId != null) {
      return _buildChatScreen(context, state, notifier, exercise);
    }

    return _buildIntroScreen(context, exercise, state, notifier);
  }

  // 1. ÉCRAN INTRO
  Widget _buildIntroScreen(
    BuildContext context, 
    ExerciceResponse exercise, 
    SimulationState state,
    SimulationNotifier notifier
  ) {
    final userProgress = ref.watch(userProgressProvider);
    final bestScore = userProgress.value?.bestScore ?? 0;
    final streak = userProgress.value?.streak ?? 0;

    String clarityValue;
    if (bestScore >= 80) {
      clarityValue = 'Excellent';
    } else if (bestScore >= 60) {
      clarityValue = 'Bien';
    } else {
      clarityValue = 'À renforcer';
    }

    String confidenceValue;
    if (streak >= 7) {
      confidenceValue = 'Élevée';
    } else if (streak >= 3) {
      confidenceValue = 'Moyenne';
    } else {
      confidenceValue = 'À renforcer';
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        title: Text(
          'Simulation IA',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [AppTheme.secondaryContainer, AppTheme.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryContainer.withAlpha((0.15 * 255).round()),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Préparez-vous avec un recruteur IA',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Exercez-vous sur des questions comportementales et techniques, puis recevez un débrief personnalisé.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withAlpha((0.88 * 255).round())),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MiniBadge(label: 'Catégorie', value: exercise.domaine),
                          _MiniBadge(label: 'Difficulté', value: exercise.difficulte),
                          _MiniBadge(label: 'Mode', value: 'Réponses vocales'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        exercise.titre,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AppTheme.primaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (exercise.description ?? '').isEmpty ? 'Notre recruteur virtuel IA va analyser vos réponses et générer un score factuel.' : (exercise.description ?? ''),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'Clarté',
                              value: clarityValue,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              label: 'Confiance',
                              value: confidenceValue,
                              color: AppTheme.primaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Personnaliser la simulation',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.primaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          labelText: 'Sujet ou domaine cible',
                          hintText: 'Ex: Flutter, data science, RH, vente B2B...',
                          filled: true,
                          fillColor: AppTheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nombre de questions',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                          ),
                          Text(
                            '$_questionCount',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                          ),
                        ],
                      ),
                      Slider(
                        value: _questionCount.toDouble(),
                        min: 10,
                        max: 30,
                        divisions: 20,
                        label: '$_questionCount questions',
                        onChanged: (value) {
                          setState(() => _questionCount = value.round());
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildModelSelector(context, ref),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                state.isLoading
                    ? Column(
                        children: [
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
                            'Initialisation de la simulation...',
                            style: TextStyle(
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : ElevatedButton.icon(
                        onPressed: () async {
                          _progressController.forward(from: 0.0);
                          try {
                            final modelsData = ref.read(availableModelsProvider).value;
                            final primaryModel = modelsData?['primary_model'] as String?;
                            final selectedModel = ref.read(selectedModelProvider) ?? primaryModel;

                            await notifier.start(
                              exercise.id,
                              subject: _subjectController.text,
                              questionCount: _questionCount,
                              model: selectedModel,
                            );
                            _progressController.value = 1.0;
                          } catch (e) {
                            _progressController.stop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.mic, size: 24, color: Colors.white),
                        label: const Text('Démarrer l\'entretien', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelSelector(BuildContext context, WidgetRef ref) {
    final modelsAsyncValue = ref.watch(availableModelsProvider);
    
    return modelsAsyncValue.when(
      data: (data) {
        final modelsList = List<String>.from(data['models'] ?? []);
        final primaryModel = data['primary_model'] as String?;
        final selectedModel = ref.watch(selectedModelProvider) ?? primaryModel;

        if (modelsList.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Modèle d\'Intelligence Artificielle',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showModelSelectorBottomSheet(context, ref, modelsList, primaryModel),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      (selectedModel?.contains('gemini') ?? false) ? Icons.auto_awesome : Icons.bolt,
                      color: (selectedModel?.contains('gemini') ?? false) ? Colors.purple : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatModelName(selectedModel ?? ''),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryContainer,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: AppTheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
        ),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Erreur lors du chargement des modèles : $err',
          style: const TextStyle(color: AppTheme.error, fontSize: 13),
        ),
      ),
    );
  }

  String _formatModelName(String modelName) {
    if (modelName.isEmpty) return 'Modèle par défaut';
    final parts = modelName.split('-');
    if (parts.isEmpty) return modelName;
    
    final formattedParts = parts.map((part) {
      if (part == 'gpt') return 'GPT';
      if (part == 'tts') return 'TTS';
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1);
    }).toList();
    
    return formattedParts.join(' ');
  }

  void _showModelSelectorBottomSheet(
    BuildContext context,
    WidgetRef ref,
    List<String> models,
    String? primaryModel,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Modèle d\'entretien',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.primaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Choisissez l\'intelligence artificielle qui mènera votre simulation d\'entretien.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: models.length,
                      itemBuilder: (context, index) {
                        final model = models[index];
                        final isPrimary = model == primaryModel;
                        final currentSelected = ref.watch(selectedModelProvider) ?? primaryModel;
                        final isSelected = model == currentSelected;
                        final isGemini = model.contains('gemini');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: isSelected ? 2 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.secondaryColor
                                  : AppTheme.outlineVariant.withAlpha((0.5 * 255).round()),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          color: isSelected
                              ? AppTheme.surfaceContainerLow
                              : Colors.white,
                          child: InkWell(
                            onTap: () {
                              ref.read(selectedModelProvider.notifier).select(model);
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isGemini
                                          ? Colors.purple.withAlpha((0.1 * 255).round())
                                          : Colors.green.withAlpha((0.1 * 255).round()),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isGemini ? Icons.auto_awesome : Icons.bolt,
                                      color: isGemini ? Colors.purple : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              _formatModelName(model),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: isSelected
                                                    ? AppTheme.primaryContainer
                                                    : AppTheme.onSurface,
                                              ),
                                            ),
                                            if (isPrimary) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryContainer,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  'Recommandé',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isGemini
                                              ? 'Fournisseur : Google Gemini'
                                              : 'Fournisseur : OpenAI',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.secondaryColor,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 2. ÉCRAN CHAT
  Widget _buildChatScreen(
    BuildContext context, 
    SimulationState state, 
    SimulationNotifier notifier,
    ExerciceResponse exercise
  ) {
    // Scroll automatique au bas à chaque nouveau message
    _scrollToBottom();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppTheme.secondaryColor,
              child: Icon(Icons.psychology, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.titre,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                  ),
                  const Text('Recruteur IA actif', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: AppTheme.error),
            tooltip: 'Annuler',
            onPressed: state.isLoading ? null : () => _cancelSimulation(notifier),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live coaching', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryContainer)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: state.questionCount == 0
                            ? 0
                            : (state.answerCount / state.questionCount).clamp(0, 1).toDouble(),
                        backgroundColor: AppTheme.surfaceContainerLow,
                        color: AppTheme.secondaryColor,
                        minHeight: 6,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${state.answerCount}/${state.questionCount} questions repondues${state.subject == null || state.subject!.isEmpty ? '' : ' - ${state.subject}'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Text('Répondez avec confiance, structurez votre pensée, et laissez l\'IA vous guider.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('🔊 En direct', style: TextStyle(color: AppTheme.onSecondaryContainer, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.outlineVariant),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.messages.length,
                itemBuilder: (context, index) {
                  final message = state.messages[index];
                  return _buildChatBubble(message);
                },
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Row(
                   children: [
                     const SizedBox(width: 4),
                     // Bouton d'enregistrement vocal
                     _MicButton(),
                     const SizedBox(width: 8),
                     Expanded(
                       child: TextField(
                         controller: _textController,
                         maxLines: null,
                         decoration: InputDecoration(
                           hintText: 'Saisissez votre réponse...',
                           fillColor: AppTheme.surface,
                           filled: true,
                           border: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(16),
                             borderSide: BorderSide.none,
                           ),
                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                         ),
                         onSubmitted: (_) => _sendAnswer(notifier),
                       ),
                     ),
                     const SizedBox(width: 8),
                     state.isLoading
                         ? const SizedBox(
                             width: 28,
                             height: 28,
                             child: CircularProgressIndicator(strokeWidth: 2),
                           )
                         : IconButton(
                             icon: const Icon(Icons.send, color: AppTheme.secondaryColor),
                             onPressed: () => _sendAnswer(notifier),
                           ),
                   ],
                 ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Appuyez sur le micro pour parler',
                      style: TextStyle(fontSize: 10, color: AppTheme.outline),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await notifier.finish();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Terminer l\'entretien', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              backgroundColor: AppTheme.secondaryContainer,
              child: Icon(Icons.psychology, size: 20, color: AppTheme.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser ? AppTheme.primaryContainer : Colors.white,
                border: message.isUser ? null : Border.all(color: AppTheme.outlineVariant),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: message.isUser ? const Radius.circular(12) : Radius.zero,
                  bottomRight: message.isUser ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : AppTheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  if (!message.isUser && message.scorePartiel != null) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ScoreChip(label: 'Score', value: '${message.scorePartiel!.round()}%'),
                        if (message.analysis != null)
                          _ScoreChip(
                            label: 'Structure',
                            value: '${((message.analysis!['structure'] as num?)?.round() ?? 0)}%',
                          ),
                        if (message.analysis != null)
                          _ScoreChip(
                            label: 'Precision',
                            value: '${((message.analysis!['precision'] as num?)?.round() ?? 0)}%',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            const CircleAvatar(
              backgroundColor: AppTheme.outline,
              child: Icon(Icons.person, size: 20, color: Colors.white),
            ),
          ]
        ],
      ),
    );
  }

  // 3. ÉCRAN EVALUATION / REPORT
  Widget _buildFeedbackScreen(
    BuildContext context, 
    SimulationState state,
    SimulationNotifier notifier
  ) {
    final feedback = state.feedback!;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        title: const Text('Bilan d\'Évaluation IA', style: TextStyle(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Radial score banner
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'VOTRE SCORE GLOBAL',
                    style: TextStyle(color: AppTheme.primaryFixedVariant, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: feedback.scoreGlobal / 100,
                          strokeWidth: 14,
                          backgroundColor: Colors.white.withAlpha((0.15 * 255).round()),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.tertiaryFixed),
                        ),
                      ),
                      Text(
                        '${feedback.scoreGlobal.round()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Entretien complété avec succès !',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Points forts (Green)
            if (feedback.pointsForts != null && feedback.pointsForts!.isNotEmpty) ...[
              _buildSectionTitle(context, Icons.check_circle, 'Points Forts', Colors.green),
              const SizedBox(height: 12),
              ...feedback.pointsForts!.map((pf) => _buildDetailCard(
                context,
                title: pf['domaine'] as String? ?? 'Compétence',
                description: pf['note'] as String? ?? '',
                borderColor: Colors.green,
                iconColor: Colors.green,
              )),
              const SizedBox(height: 32),
            ],

            // Axes d'amélioration (Orange)
            if (feedback.ameliorations != null && feedback.ameliorations!.isNotEmpty) ...[
              _buildSectionTitle(context, Icons.trending_up, 'Axes d\'Amélioration', Colors.orange),
              const SizedBox(height: 12),
              ...feedback.ameliorations!.map((am) => _buildDetailCard(
                context,
                title: am['domaine'] as String? ?? 'Compétence',
                description: am['note'] as String? ?? '',
                borderColor: Colors.orange,
                iconColor: Colors.orange,
              )),
              const SizedBox(height: 32),
            ],

            // Recommandations
            if (feedback.recommandations != null && feedback.recommandations!.isNotEmpty) ...[
              _buildSectionTitle(context, Icons.assignment, 'Recommandations de l\'IA', AppTheme.secondaryColor),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  border: Border.all(color: AppTheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: feedback.recommandations!.map((rec) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star, color: AppTheme.secondaryColor, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            rec,
                            style: const TextStyle(fontSize: 14, color: AppTheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 48),
            ],

            // Button Return to Dashboard
            ElevatedButton(
              onPressed: () {
                notifier.reset();
                ref.invalidate(userProgressProvider);
                ref.invalidate(sessionHistoryProvider);
                ref.invalidate(detailedStatsProvider);
                context.go('/dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Retour au Tableau de Bord', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryContainer,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color borderColor,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.02 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final String value;

  const _MiniBadge({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryContainer,
                  ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final String value;

  const _ScoreChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: AppTheme.onSecondaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha((0.2 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryContainer,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

/// Bouton microphone interactif avec animation de pulse.
/// Utilise l'enregistrement audio réel et l'envoie au backend pour transcription.
class _MicButton extends ConsumerStatefulWidget {
  const _MicButton();

  @override
  ConsumerState<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends ConsumerState<_MicButton>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    final notifier = ref.read(simulationProvider.notifier);
    if (_isRecording) {
      try {
        await notifier.stopAndSendRecording();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.mic_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Transcription terminée'),
                ],
              ),
              duration: Duration(seconds: 2),
              backgroundColor: AppTheme.primaryContainer,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur de transcription: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
      if (mounted) setState(() => _isRecording = false);
    } else {
      try {
        await notifier.startRecording();
        setState(() => _isRecording = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.mic, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Enregistrement en cours...'),
                ],
              ),
              duration: Duration(seconds: 2),
              backgroundColor: AppTheme.secondaryColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isRecording ? _pulseAnimation.value : 1.0,
          child: IconButton(
            icon: Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              color: _isRecording ? AppTheme.error : AppTheme.outline,
            ),
            tooltip: _isRecording ? 'Arrêter l\'enregistrement' : 'Enregistrer une réponse vocale',
            style: IconButton.styleFrom(
              backgroundColor: _isRecording
                  ? AppTheme.error.withAlpha((0.12 * 255).round())
                  : Colors.transparent,
            ),
            onPressed: _toggleRecording,
          ),
        );
      },
    );
  }
}
