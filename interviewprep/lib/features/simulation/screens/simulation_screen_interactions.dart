part of 'simulation_screen.dart';

mixin _SimulationInteractions on ConsumerState<SimulationScreen> {
  TextEditingController get _textController;
  ScrollController get _scrollController;

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

  void sendAnswerFromScreen(SimulationNotifier notifier) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    try {
      await notifier.sendAnswer(text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> cancelSimulationFromScreen(SimulationNotifier notifier) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la simulation ?'),
        content: const Text(
          'La session sera marquee comme annulee et aucun bilan ne sera genere.',
        ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
}
