part of 'simulation_screen.dart';

mixin _SimulationIntro on ConsumerState<SimulationScreen> {
  TextEditingController get _subjectController;
  int get _questionCount;
  set _questionCount(int value);
  Widget buildModelSelector(BuildContext context, WidgetRef ref);

  Widget _buildIntroScreen(
    BuildContext context,
    ExerciceResponse exercise,
    SimulationState state,
    SimulationNotifier notifier,
  ) {
    final progress = ref.watch(userProgressProvider).value;
    return SimulationIntroView(
      exercise: exercise,
      state: state,
      subjectController: _subjectController,
      questionCount: _questionCount,
      bestScore: progress?.bestScore ?? 0,
      streak: progress?.streak ?? 0,
      modelSelector: buildModelSelector(context, ref),
      onQuestionCountChanged: (value) => setState(() => _questionCount = value),
      onStart: () => _startSimulation(exercise, notifier),
    );
  }

  Future<void> _startSimulation(
    ExerciceResponse exercise,
    SimulationNotifier notifier,
  ) async {
    final models = ref.read(availableModelsProvider).value;
    await notifier.start(
      exercise.id,
      subject: _subjectController.text,
      questionCount: _questionCount,
      model: ref.read(selectedModelProvider) ?? models?['primary_model'],
    );
  }
}

class SimulationIntroView extends StatelessWidget {
  const SimulationIntroView({
    super.key,
    required this.exercise,
    required this.state,
    required this.subjectController,
    required this.questionCount,
    required this.bestScore,
    required this.streak,
    required this.modelSelector,
    required this.onQuestionCountChanged,
    required this.onStart,
  });

  final ExerciceResponse exercise;
  final SimulationState state;
  final TextEditingController subjectController;
  final int questionCount;
  final double bestScore;
  final int streak;
  final Widget modelSelector;
  final ValueChanged<int> onQuestionCountChanged;
  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Simulation IA')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Préparez-vous avec un recruteur IA',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(exercise.titre),
                Text(exercise.description ?? ''),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Clarté',
                        value: _clarity,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    Expanded(
                      child: _StatTile(
                        label: 'Confiance',
                        value: _confidence,
                        color: AppTheme.primaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SimulationCustomizationCard(
                  subjectController: subjectController,
                  questionCount: questionCount,
                  onQuestionCountChanged: onQuestionCountChanged,
                  modelSelector: modelSelector,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: state.isLoading ? null : onStart,
                  icon: const Icon(Icons.mic),
                  label: Text(
                    state.isLoading
                        ? 'Initialisation...'
                        : 'Démarrer l’entretien',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _clarity => bestScore >= 80
      ? 'Excellent'
      : bestScore >= 60
      ? 'Bien'
      : 'À renforcer';

  String get _confidence => streak >= 7
      ? 'Élevée'
      : streak >= 3
      ? 'Moyenne'
      : 'À renforcer';
}
