import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/exercise.dart';

class DashboardService {
  final ApiClient _apiClient = ApiClient();

  Future<UserProgress> getUserProgress() async {
    try {
      final response = await _apiClient.dio.get('/progress/me');
      return UserProgress.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        ApiClient.errorMessage(e, 'Erreur lors du chargement des progrès'),
      );
    }
  }

  Future<List<Session>> getSessionHistory({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/progress/history',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => Session.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
        ApiClient.errorMessage(e, 'Erreur lors du chargement de l\'historique'),
      );
    }
  }

  Future<Map<String, dynamic>> getDetailedStats() async {
    try {
      final response = await _apiClient.dio.get('/progress/stats');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        ApiClient.errorMessage(e, 'Erreur lors du chargement des statistiques'),
      );
    }
  }
}
