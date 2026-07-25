import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/exercise_service.dart';
import '../../../core/models/exercise_models.dart';

final exerciseServiceProvider = Provider<ExerciseService>((ref) {
  return ExerciseService();
});

class ExerciseFilters {
  final String? domaine;
  final String? difficulte;

  const ExerciseFilters({this.domaine, this.difficulte});

  ExerciseFilters copyWith({String? domaine, String? difficulte, bool clearDomaine = false, bool clearDifficulte = false}) {
    return ExerciseFilters(
      domaine: clearDomaine ? null : (domaine ?? this.domaine),
      difficulte: clearDifficulte ? null : (difficulte ?? this.difficulte),
    );
  }
}

class ExerciseFiltersNotifier extends Notifier<ExerciseFilters> {
  @override
  ExerciseFilters build() => const ExerciseFilters();

  void setDomaine(String? domaine) {
    if (domaine == 'Tous' || domaine == null) {
      state = state.copyWith(clearDomaine: true);
    } else {
      state = state.copyWith(domaine: domaine);
    }
  }

  void setDifficulte(String? difficulte) {
    if (difficulte == 'Tous' || difficulte == null) {
      state = state.copyWith(clearDifficulte: true);
    } else {
      state = state.copyWith(difficulte: difficulte);
    }
  }

  void reset() {
    state = const ExerciseFilters();
  }
}

final exerciseFiltersProvider = NotifierProvider<ExerciseFiltersNotifier, ExerciseFilters>(() {
  return ExerciseFiltersNotifier();
});

final exercisesListProvider = FutureProvider<List<ExerciceResponse>>((ref) async {
  final service = ref.watch(exerciseServiceProvider);
  final filters = ref.watch(exerciseFiltersProvider);
  
  return await service.getExercises(
    domaine: filters.domaine,
    difficulte: filters.difficulte,
  );
});

class SelectedExerciseNotifier extends Notifier<ExerciceResponse?> {
  @override
  ExerciceResponse? build() => null;

  void select(ExerciceResponse? exercise) => state = exercise;
}

final selectedExerciseProvider = NotifierProvider<SelectedExerciseNotifier, ExerciceResponse?>(() {
  return SelectedExerciseNotifier();
});

final exerciseGenerationProvider = AsyncNotifierProvider<ExerciseGenerationNotifier, ExerciceResponse?>(() {
  return ExerciseGenerationNotifier();
});

class ExerciseGenerationNotifier extends AsyncNotifier<ExerciceResponse?> {
  @override
  FutureOr<ExerciceResponse?> build() => null;

  Future<ExerciceResponse> generate({
    required String domaine,
    required String difficulte,
    String? sujet,
    int nombreQuestions = 10,
  }) async {
    state = const AsyncValue.loading();
    final service = ref.read(exerciseServiceProvider);
    
    final value = await AsyncValue.guard(() async {
      return await service.generateExercise({
        'domaine': domaine,
        'difficulte': difficulte,
        'sujet': sujet,
        'nombreQuestions': nombreQuestions,
      });
    });

    if (value.hasError) {
      state = AsyncValue.error(value.error!, value.stackTrace!);
      throw value.error!;
    }

    state = AsyncValue.data(value.value);
    ref.invalidate(exercisesListProvider);
    return value.value!;
  }
}
