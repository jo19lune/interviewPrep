import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/session_models.dart';

class SimulationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<String>> getModels() async {
    try {
      final response = await _apiClient.dio.get('/simulation/models');
      return List<String>.from(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des modèles');
    }
  }

  Future<SessionResponse> startSimulation(String exerciseId) async {
    try {
      // Assuming payload has exercice_id
      final response = await _apiClient.dio.post('/simulation/start', data: {'exercice_id': exerciseId});
      return SessionResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors du démarrage de la simulation');
    }
  }

  Future<void> sendAnswer(String sessionId, String content) async {
    try {
      await _apiClient.dio.post('/simulation/answer', data: {
        'session_id': sessionId,
        'content': content,
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de la réponse');
    }
  }

  // Stream could be using http directly or dio with stream response type
  Stream<String> getStream(String sessionId) async* {
    try {
      final response = await _apiClient.dio.get(
        '/simulation/stream/$sessionId',
        options: Options(responseType: ResponseType.stream),
      );
      
      final stream = response.data.stream;
      await for (var chunk in stream) {
        // Assume chunk is List<int> and needs to be decoded from UTF-8 to string
        // Often we parse SSE format here, but returning raw string for now
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
