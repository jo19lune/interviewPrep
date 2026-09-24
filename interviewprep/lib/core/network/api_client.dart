import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../env.dart';

class ApiClient {
  static String get apiKey => Env.backendApiKey;
  static String get baseUrl =>
      '${Env.apiBaseUrl}/api/v1';

  static String errorMessage(DioException error, String fallback) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) return 'Non autorisé';
    if (statusCode == 429) return 'Trop de requêtes, veuillez patienter';
    if (statusCode == 503) return 'Service indisponible';

    final data = error.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is List) {
        return detail.map((item) => item.toString()).join('\n');
      }
      if (detail is Map) {
        final code = detail['code'];
        final msg = detail['message'] ?? detail['msg'] ?? detail['detail'];
        if (msg != null) {
          if (code != null) {
            return '[$code] $msg';
          }
          return msg.toString();
        }
      }
      if (detail != null) {
        return detail.toString();
      }
      final code = data['code'];
      final message = data['message'];
      if (message != null) {
        if (code != null) {
          return '[$code] $message';
        }
        return message.toString();
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    return fallback;
  }

  final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio _refreshDio;

  ApiClient() : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
    _refreshDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (apiKey.isNotEmpty) {
            options.headers['X-API-Key'] = apiKey;
          }
          return handler.next(options);
        },
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (apiKey.isNotEmpty) {
            options.headers['X-API-Key'] = apiKey;
          }
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 &&
              e.requestOptions.path != '/auth/refresh') {
            final refreshed = await _refreshTokens();
            if (refreshed) {
              try {
                final token = await _storage.read(key: 'access_token');
                final options = e.requestOptions;
                options.headers['Authorization'] = 'Bearer $token';
                final response = await dio.fetch(options);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                await removeTokens();
                return handler.next(retryError);
              }
            }
            await removeTokens();
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> saveToken(String token) async {
    await saveTokens(accessToken: token);
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }
  }

  Future<void> removeTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<void> removeToken() async {
    await removeTokens();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<bool> _refreshTokens() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) {
      return false;
    }

    try {
      final response = await _refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final accessToken = response.data['access_token'] as String?;
      final newRefreshToken = response.data['refresh_token'] as String?;
      if (accessToken == null || newRefreshToken == null) {
        return false;
      }
      await saveTokens(accessToken: accessToken, refreshToken: newRefreshToken);
      return true;
    } on DioException {
      return false;
    }
  }
}
