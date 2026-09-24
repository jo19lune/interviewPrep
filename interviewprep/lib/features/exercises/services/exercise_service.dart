import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/exercise_models.dart';

class ExerciseService {
  final ApiClient _apiClient = ApiClient();

  String _formatError(dynamic e, String fallback) {
    if (e is DioException) return ApiClient.errorMessage(e, fallback);
    if (e is Exception) return e.toString().replaceAll('Exception: ', '');
    return fallback;
  }

  Future<List<ExerciceResponse>> getExercises({
    String? domaine,
    String? difficulte,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (domaine != null) queryParams['domaine'] = domaine;
      if (difficulte != null) queryParams['difficulte'] = difficulte;

      final response = await _apiClient.dio.get(
        '/exercises',
        queryParameters: queryParams,
      );
      return (response.data as List)
          .map((e) => ExerciceResponse.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception(
        _formatError(e, 'Erreur lors de la récupération des exercices'),
      );
    }
  }

  Future<ExerciceResponse> getExercise(String id) async {
    try {
      final response = await _apiClient.dio.get('/exercises/$id');
      return ExerciceResponse.fromJson(response.data);
    } catch (e) {
      throw Exception(
        _formatError(e, 'Erreur lors de la récupération de l\'exercice'),
      );
    }
  }

  Future<ExerciceResponse> getRandomExercise({
    String? domaine,
    String? difficulte,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (domaine != null) queryParams['domaine'] = domaine;
      if (difficulte != null) queryParams['difficulte'] = difficulte;

      final response = await _apiClient.dio.get(
        '/exercises/random/get',
        queryParameters: queryParams,
      );
      return ExerciceResponse.fromJson(response.data);
    } catch (e) {
      throw Exception(
        _formatError(
          e,
          'Erreur lors de la récupération d\'un exercice aléatoire',
        ),
      );
    }
  }

  Future<ExerciceResponse> createExercise(ExerciceCreateRequest req) async {
    try {
      final response = await _apiClient.dio.post(
        '/exercises/',
        data: req.toJson(),
      );
      return ExerciceResponse.fromJson(response.data);
    } catch (e) {
      throw Exception(
        _formatError(e, 'Erreur lors de la création de l\'exercice'),
      );
    }
  }

  Future<ExerciceResponse> generateExercise(Map<String, dynamic> params) async {
    try {
      final response = await _apiClient.dio.post(
        '/exercises/generate',
        data: params,
      );
      return ExerciceResponse.fromJson(response.data);
    } catch (e) {
      throw Exception(
        _formatError(e, 'Erreur lors de la génération de l\'exercice'),
      );
    }
  }
}
