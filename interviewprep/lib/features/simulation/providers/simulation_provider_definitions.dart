part of 'simulation_provider.dart';

final simulationServiceProvider = Provider<SimulationService>((ref) {
  return SimulationService();
});

final availableModelsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(simulationServiceProvider).getAvailableModels();
});

class SelectedModelNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? model) => state = model;
}

final selectedModelProvider = NotifierProvider<SelectedModelNotifier, String?>(
  SelectedModelNotifier.new,
);

String _generateId() =>
    'sim_msg_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';

final simulationProvider =
    NotifierProvider<SimulationNotifier, SimulationState>(
      SimulationNotifier.new,
    );
