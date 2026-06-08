import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../exercises/providers/exercise_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/simulation_provider.dart';
import '../../../core/models/exercise.dart' as models;

class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({super.key});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  final _textController = TextEditingController();
  final _subjectController = TextEditingController();
  final _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();
  int _questionCount = 10;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _textController.dispose();
    _subjectController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setSpeechRate(0.9);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur synthèse vocale')),
        );
      }
    }
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

  // Synthèse vocale de la question
  void _speakCurrentQuestion() {
    final state = ref.read(simulationProvider);
    final lastMessage = state.messages.isNotEmpty ? state.messages.last : null;
    if (lastMessage != null && !lastMessage.isUser) {
      _speak(lastMessage.text);
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
    models.Exercise exercise, 
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
                        exercise.description ?? 'Notre recruteur virtuel IA va analyser vos réponses et générer un score factuel.',
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await notifier.start(
                              exercise.id,
                              subject: _subjectController.text,
                              questionCount: _questionCount,
                            );
                          } catch (e) {
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

  // 2. ÉCRAN CHAT
  Widget _buildChatScreen(
    BuildContext context, 
    SimulationState state, 
    SimulationNotifier notifier,
    models.Exercise exercise
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
          if (state.lastLiveCoachingTip != null && state.lastLiveCoachingTip!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                border: Border.all(color: AppTheme.secondaryContainer),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.secondaryColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CONSEIL DE COACHING',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.lastLiveCoachingTip!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurface),
                        ),
                      ],
                    ),
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
                     IconButton(
                       icon: Icon(
                         Icons.volume_up,
                         color: AppTheme.secondaryColor,
                       ),
                       tooltip: 'Écouter la question',
                       onPressed: () => _speakCurrentQuestion(),
                     ),
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
