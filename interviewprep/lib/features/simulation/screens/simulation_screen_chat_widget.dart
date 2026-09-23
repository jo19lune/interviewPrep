part of 'simulation_screen.dart';

mixin _SimulationChat on ConsumerState<SimulationScreen> {
  TextEditingController get _textController;
  ScrollController get _scrollController;
  void _scrollToBottom();
  void _sendAnswer(SimulationNotifier notifier);
  Future<void> _cancelSimulation(SimulationNotifier notifier);

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
      onCancel: () => _cancelSimulation(notifier),
      onSend: () => _sendAnswer(notifier),
      onFinish: () => notifier.finish(),
    );
  }
}
