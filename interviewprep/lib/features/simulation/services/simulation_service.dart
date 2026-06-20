import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/session_models.dart';

class SimulationService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getAvailableModels() async {
    try {
      final response = await _apiClient.dio.get('/simulation/models');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des modèles');
    }
  }

  Future<SessionResponse> startSimulation(String exerciseId, {String? subject, int? questionCount, String? model}) async {
    try {
      final response = await _apiClient.dio.post('/simulation/start', data: {
        'exercice_id': exerciseId,
        if (subject != null) 'subject': subject,
        if (questionCount != null) 'question_count': questionCount,
        if (model != null) 'model': model,
      });
      return SessionResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors du démarrage de la simulation');
    }
  }

  Future<Map<String, dynamic>> submitAnswer(String sessionId, String content) async {
    try {
      final response = await _apiClient.dio.post('/simulation/answer', data: {
        'session_id': sessionId,
        'content': content,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de la réponse');
    }
  }

  Stream<String> streamAIResponse(String sessionId) async* {
    try {
      final response = await _apiClient.dio.get(
        '/simulation/stream/$sessionId',
        options: Options(responseType: ResponseType.stream),
      );
      
      final stream = response.data.stream;
      await for (var chunk in stream) {
        yield String.fromCharCodes(chunk);
      }
    } catch (e) {
      throw Exception('Erreur lors de la connexion au stream');
    }
  }

  Future<void> cancelSimulation(String sessionId) async {
    try {
      await _apiClient.dio.post('/simulation/cancel/$sessionId');
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de la simulation');
    }
  }

  Future<FeedbackResponse> finishSimulation(String sessionId) async {
    try {
      final response = await _apiClient.dio.post('/simulation/finish/$sessionId');
      return FeedbackResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la fin de la simulation');
    }
  }
}
