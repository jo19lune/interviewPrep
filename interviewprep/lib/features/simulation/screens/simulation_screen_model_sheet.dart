part of 'simulation_screen.dart';

class ModelSelectorSheet extends StatelessWidget {
  const ModelSelectorSheet({
    super.key,
    required this.models,
    required this.primaryModel,
    required this.ref,
  });

  final List<String> models;
  final String? primaryModel;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const SizedBox(
              width: 40,
              height: 4,
              child: ColoredBox(color: AppTheme.outlineVariant),
            ),
            const SizedBox(height: 18),
            Text(
              'Modèle d’entretien',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Choisissez l’intelligence artificielle qui mènera votre simulation d’entretien.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(16),
                itemCount: models.length,
                itemBuilder: (context, index) => ModelOptionTile(
                  model: models[index],
                  selectedModel:
                      ref.watch(selectedModelProvider) ?? primaryModel,
                  onSelected: () {
                    ref
                        .read(selectedModelProvider.notifier)
                        .select(models[index]);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModelOptionTile extends StatelessWidget {
  const ModelOptionTile({
    super.key,
    required this.model,
    required this.selectedModel,
    required this.onSelected,
  });

  final String model;
  final String? selectedModel;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = model == selectedModel;
    final gemini = model.contains('gemini');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: selected ? AppTheme.surfaceContainerLow : Colors.white,
      child: ListTile(
        onTap: onSelected,
        leading: Icon(gemini ? Icons.auto_awesome : Icons.bolt),
        title: Text(model),
        subtitle: Text(
          gemini ? 'Fournisseur : Google Gemini' : 'Fournisseur : OpenAI',
        ),
        trailing: selected ? const Icon(Icons.check_circle) : null,
      ),
    );
  }
}
