import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/progress.dart';
import '../../../core/models/session_models.dart';
import '../../../core/models/session_detail.dart';

class DashboardService {
  final ApiClient _apiClient = ApiClient();

  String _formatError(dynamic e, String fallback) {
    if (e is DioException) return ApiClient.errorMessage(e, fallback);
    if (e is Exception) return e.toString().replaceAll('Exception: ', '');
    return fallback;
  }

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

  Future<List<SessionResponse>> getAllSessions({int skip = 0, int limit = 50}) async {
    try {
      final response = await _apiClient.dio.get('/simulation/sessions', queryParameters: {
        'skip': skip,
        'limit': limit,
      });
      return (response.data as List).map((e) => SessionResponse.fromJson(e)).toList();
    } catch (e) {
      throw Exception(_formatError(e, 'Erreur lors de la récupération des sessions'));
    }
  }

  Future<SessionConversation> getSessionConversation(String sessionId) async {
    try {
      final response = await _apiClient.dio.get('/simulation/sessions/$sessionId');
      return SessionConversation.fromJson(response.data);
    } catch (e) {
      throw Exception(_formatError(e, 'Erreur lors de la récupération de la conversation'));
    }
  }
}
