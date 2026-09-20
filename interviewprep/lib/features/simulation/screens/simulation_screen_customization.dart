part of 'simulation_screen.dart';

class SimulationCustomizationCard extends StatelessWidget {
  const SimulationCustomizationCard({
    super.key,
    required this.subjectController,
    required this.questionCount,
    required this.onQuestionCountChanged,
    required this.modelSelector,
  });

  final TextEditingController subjectController;
  final int questionCount;
  final ValueChanged<int> onQuestionCountChanged;
  final Widget modelSelector;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            controller: subjectController,
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryContainer,
                ),
              ),
              Text(
                '$questionCount',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
          Slider(
            value: questionCount.toDouble(),
            min: 10,
            max: 30,
            divisions: 20,
            label: '$questionCount questions',
            onChanged: (value) => onQuestionCountChanged(value.round()),
          ),
          const SizedBox(height: 18),
          modelSelector,
        ],
      ),
    );
  }
}
