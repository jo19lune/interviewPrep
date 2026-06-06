import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/exercise.dart';

class ExerciseService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Exercise>> getExercises({
    String? domaine,
    String? difficulte,
    String? tags,
    int skip = 0,
    int limit = 10,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'domaine': ?domaine,
        'difficulte': ?difficulte,
        'tags': ?tags,
        'skip': skip,
        'limit': limit,
      };
      final response = await _apiClient.dio.get(
        '/exercises',
        queryParameters: queryParameters,
      );

      final List<dynamic> data = response.data;
      return data.map((json) => Exercise.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Erreur lors du chargement des exercices');
    }
  }

  Future<Exercise> getExercise(String id) async {
    try {
      final response = await _apiClient.dio.get('/exercises/$id');
      return Exercise.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Exercice non trouvé');
    }
  }

  Future<Exercise> getRandomExercise({
    String? domaine,
    String? difficulte,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'domaine': ?domaine,
        'difficulte': ?difficulte,
      };
      final response = await _apiClient.dio.get(
        '/exercises/random/get',
        queryParameters: queryParameters,
      );
      return Exercise.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Aucun exercice trouvé');
    }
  }
}
