import 'package:dio/dio.dart';
import '../../../core/models/activity_history.dart';
import '../../../core/network/api_client.dart';

class ActivityHistoryService {
  final ApiClient _apiClient = ApiClient();

  String _formatError(dynamic error, String fallback) {
    if (error is DioException) {
      return ApiClient.errorMessage(error, fallback);
    }
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return fallback;
  }

  Future<List<ActivityHistory>> list({
    int skip = 0,
    int limit = 50,
    String? type,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/activities',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (type != null && type.isNotEmpty) 'type': type,
        },
      );
      return (response.data as List)
          .map((item) => ActivityHistory.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw Exception(
        _formatError(error, 'Erreur lors de la récupération des activités'),
      );
    }
  }

  Future<ActivityHistory> create({
    required String type,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/activities',
        data: {'type': type, 'message': message, 'metadata': metadata},
      );
      return ActivityHistory.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      throw Exception(
        _formatError(error, 'Erreur lors de la création de l’activité'),
      );
    }
  }

  Future<ActivityHistory> update(
    String id, {
    String? type,
    String? message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/activities/$id',
        data: {
          ...?type != null ? {'type': type} : null,
          ...?message != null ? {'message': message} : null,
          ...?metadata != null ? {'metadata': metadata} : null,
        },
      );
      return ActivityHistory.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      throw Exception(
        _formatError(error, 'Erreur lors de la modification de l’activité'),
      );
    }
  }

  Future<void> delete(String id) async {
    try {
      await _apiClient.dio.delete('/activities/$id');
    } catch (error) {
      throw Exception(
        _formatError(error, 'Erreur lors de la suppression de l’activité'),
      );
    }
  }
}
