import '../../../core/network/api_client.dart';
import '../../../core/models/progress.dart';
import '../../../core/models/session_models.dart';

class DashboardService {
  final ApiClient _apiClient = ApiClient();

  Future<ProgressMeResponse> getUserProgress() async {
    try {
      final response = await _apiClient.dio.get('/progress/me');
      return ProgressMeResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la progression de l\'utilisateur');
    }
  }

  Future<Map<String, dynamic>> getDetailedStats() async {
    try {
      final response = await _apiClient.dio.get('/progress/stats');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques');
    }
  }

  Future<List<SessionResponse>> getSessionHistory({int skip = 0, int limit = 50}) async {
    try {
      final response = await _apiClient.dio.get('/progress/history', queryParameters: {
        'skip': skip,
        'limit': limit,
      });
      return (response.data as List).map((e) => SessionResponse.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'historique');
    }
  }

  Future<dynamic> exportData() async {
    try {
      final response = await _apiClient.dio.get('/progress/export');
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de l\'exportation des données');
    }
  }
}
