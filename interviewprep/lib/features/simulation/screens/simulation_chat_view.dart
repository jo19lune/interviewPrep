part of 'simulation_screen.dart';

class SimulationChatView extends StatelessWidget {
  const SimulationChatView({
    super.key,
    required this.state,
    required this.exercise,
    required this.textController,
    required this.scrollController,
    required this.onCancel,
    required this.onSend,
    required this.onFinish,
  });

  final SimulationState state;
  final ExerciceResponse exercise;
  final TextEditingController textController;
  final ScrollController scrollController;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  final Future<void> Function() onFinish;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(exercise.titre),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: AppTheme.error),
            onPressed: state.isLoading ? null : onCancel,
          ),
        ],
      ),
      body: Column(
        children: [
          _ProgressPanel(state: state),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.messages.length,
              itemBuilder: (context, index) =>
                  _SimulationChatBubble(message: state.messages[index]),
            ),
          ),
          _ChatComposer(
            state: state,
            controller: textController,
            onSend: onSend,
            onFinish: onFinish,
          ),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.state});

  final SimulationState state;

  @override
  Widget build(BuildContext context) {
    final progress = state.questionCount == 0
        ? 0.0
        : (state.answerCount / state.questionCount).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Live coaching'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 6),
          Text(
            '${state.answerCount}/${state.questionCount} questions répondues',
          ),
        ],
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.state,
    required this.controller,
    required this.onSend,
    required this.onFinish,
  });

  final SimulationState state;
  final TextEditingController controller;
  final VoidCallback onSend;
  final Future<void> Function() onFinish;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Saisissez votre réponse...',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppTheme.secondaryColor),
            onPressed: state.isLoading ? null : onSend,
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle, color: AppTheme.error),
            onPressed: state.isLoading ? null : onFinish,
          ),
        ],
      ),
    );
  }
}

class _SimulationChatBubble extends StatelessWidget {
  const _SimulationChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.isUser ? AppTheme.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : AppTheme.onSurface,
          ),
        ),
      ),
    );
  }
}
