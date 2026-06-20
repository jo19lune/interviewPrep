import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/exercise.dart';

class SimulationService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getAvailableModels() async {
    try {
      final response = await _apiClient.dio.get('/simulation/models');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        ApiClient.errorMessage(e, 'Erreur lors de la récupération des modèles'),
      );
    }
  }

  Future<StartSimulationResponse> startSimulation(
    String exerciseId, {
    String? subject,
    int questionCount = 10,
    String? model,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/simulation/start',
        queryParameters: {
          'exercice_id': exerciseId,
          'nombre_questions': questionCount,
          if (subject != null && subject.trim().isNotEmpty)
            'sujet': subject.trim(),
          if (model != null && model.isNotEmpty)
            'modele': model,
        },
      );
      return StartSimulationResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        ApiClient.errorMessage(e, 'Erreur lors du démarrage de la simulation'),
      );
    }
  }

  Future<Map<String, dynamic>> submitAnswer(
    String sessionId,
    String answer,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/simulation/answer',
        queryParameters: {'session_id': sessionId, 'reponse': answer},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        ApiClient.errorMessage(e, 'Erreur lors de la soumission de la réponse'),
      );
    }
  }

  Stream<String> streamAIResponse(String sessionId) async* {
    try {
      final response = await _apiClient.dio.get(
        '/simulation/stream/$sessionId',
        options: Options(responseType: ResponseType.stream),
      );
      final responseBody = response.data as ResponseBody;
      await for (final line
          in responseBody.stream
              .cast<List<int>>()
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (!line.startsWith('data:')) {
          continue;
        }
        final payload = line.substring(5).trim();
        if (payload.isEmpty || payload == '{}') {
          continue;
        }
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          final text = decoded['text'] as String?;
          if (text != null) {
            yield text;
          }
        }
      }
    } on DioException catch (e) {
      throw Exception(ApiClient.errorMessage(e, 'Erreur lors du streaming IA'));
    }
  }

  Future<Map<String, dynamic>> finishSimulation(String sessionId) async {
    try {
      final response = await _apiClient.dio.post(
        '/simulation/finish/$sessionId',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        ApiClient.errorMessage(e, 'Erreur lors de la fin de la simulation'),
      );
    }
  }

  Future<Map<String, dynamic>> cancelSimulation(String sessionId) async {
    try {
      final response = await _apiClient.dio.post(
        '/simulation/cancel/$sessionId',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        ApiClient.errorMessage(
          e,
          'Erreur lors de l annulation de la simulation',
        ),
      );
    }
  }
}
