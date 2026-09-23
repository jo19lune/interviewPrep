part of 'simulation_screen.dart';

mixin _SimulationChat on ConsumerState<SimulationScreen> {
  TextEditingController get _textController;
  ScrollController get _scrollController;
  void _scrollToBottom();
  void sendAnswerFromScreen(SimulationNotifier notifier);
  Future<void> cancelSimulationFromScreen(SimulationNotifier notifier);

  Widget _buildChatScreen(
    BuildContext context,
    SimulationState state,
    SimulationNotifier notifier,
    ExerciceResponse exercise,
  ) {
    _scrollToBottom();
    return SimulationChatView(
      state: state,
      exercise: exercise,
      textController: _textController,
      scrollController: _scrollController,
      onCancel: () => cancelSimulationFromScreen(notifier),
      onSend: () => sendAnswerFromScreen(notifier),
      onFinish: () => notifier.finish(),
    );
  }
}
