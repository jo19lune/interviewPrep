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
    } on DioException catch (e) {
      if (!mounted) return;
      if (ApiClient.errorCode(e) == 'SESSION_NOT_ACTIVE') {
        // La session est close : proposer le bilan plutôt qu'une erreur.
        _showSessionClosedDialog(notifier);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.errorMessage(e, "Erreur d'envoi"))),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _showSessionClosedDialog(SimulationNotifier notifier) async {
    final recover = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session terminee'),
        content: const Text(
          "Cette session d'entretien est close. Souhaitez-vous recuperer "
          'son bilan ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Quitter'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Voir le bilan'),
          ),
        ],
      ),
    );
    if (recover == true) {
      await notifier.finish();
    }
    if (mounted && recover != true) {
      context.go('/exercises');
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

    // Le backend est idempotent et le notifier absorbe les 409/404 : sauf
    // erreur réseau réelle, on revient toujours à la liste des exercices.
    try {
      await notifier.cancel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? ApiClient.errorMessage(e, "Erreur lors de l'annulation")
                  : "Erreur lors de l'annulation",
            ),
          ),
        );
      }
    }
    if (mounted) {
      context.go('/exercises');
    }
  }
}
