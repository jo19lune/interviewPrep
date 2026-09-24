import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../exercises/providers/exercise_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/simulation_provider.dart';
import '../../../core/models/exercise_models.dart';
import '../../qa/models/chat_message.dart';

part 'simulation_screen_interactions.dart';
part 'simulation_screen_intro_widget.dart';
part 'simulation_screen_customization.dart';
part 'simulation_screen_model_widget.dart';
part 'simulation_screen_model_sheet.dart';
part 'simulation_screen_chat_widget.dart';
part 'simulation_screen_feedback_widget.dart';
part 'simulation_screen_feedback_cards.dart';
part 'simulation_screen_support_widgets.dart';
part 'simulation_screen_mic_widget.dart';
part 'simulation_chat_view.dart';

class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({super.key});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen>
    with
        SingleTickerProviderStateMixin,
        _SimulationInteractions,
        _SimulationIntro,
        _SimulationModel,
        _SimulationChat,
        _SimulationFeedback {
  @override
  final _textController = TextEditingController();
  @override
  final _subjectController = TextEditingController();
  @override
  final _scrollController = ScrollController();
  @override
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

  @override
  Widget build(BuildContext context) {
    final exercise = ref.watch(selectedExerciseProvider);
    final state = ref.watch(simulationProvider);
    final notifier = ref.read(simulationProvider.notifier);

    // Si aucun exercice n'est sÃ©lectionnÃ©, inviter Ã  en choisir un
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
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: AppTheme.secondaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun exercice sÃ©lectionnÃ©',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 20,
                    color: AppTheme.primaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'SÃ©lectionnez d\'abord un exercice dans la liste pour commencer l\'entretien.',
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
                  child: const Text('SÃ©lectionner un exercice'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Affichage des diffÃ©rents Ã©crans selon l'Ã©tat de la simulation
    if (state.feedback != null) {
      return _buildFeedbackScreen(context, state, notifier);
    }

    if (state.sessionId != null) {
      return _buildChatScreen(context, state, notifier, exercise);
    }

    return _buildIntroScreen(context, exercise, state, notifier);
  }
}
