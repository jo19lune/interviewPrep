mixin _SimulationModel on _SimulationScreenState {
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
              'ModÃ¨le d\'Intelligence Artificielle',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showModelSelectorBottomSheet(
                context,
                ref,
                modelsList,
                primaryModel,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      (selectedModel?.contains('gemini') ?? false)
                          ? Icons.auto_awesome
                          : Icons.bolt,
                      color: (selectedModel?.contains('gemini') ?? false)
                          ? Colors.purple
                          : Colors.green,
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
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.onSurfaceVariant,
                    ),
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
          'Erreur lors du chargement des modÃ¨les : $err',
          style: const TextStyle(color: AppTheme.error, fontSize: 13),
        ),
      ),
    );
  }

  String _formatModelName(String modelName) {
    if (modelName.isEmpty) return 'ModÃ¨le par dÃ©faut';
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
      builder: (_) => ModelSelectorSheet(
        models: models,
        primaryModel: primaryModel,
        ref: ref,
      ),
    );
  }
}
