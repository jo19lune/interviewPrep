import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../env.dart';

class ApiClient {
  static String get apiKey => Env.backendApiKey;
  static String get baseUrl =>
      '${Env.apiBaseUrl}/api/v1';

  /// Code machine renvoyé par le backend via l'en-tête `X-Error-Code`
  /// (ex: `SESSION_NOT_ACTIVE`, `AI_QUOTA_EXCEEDED`).
  static String? errorCode(DioException error) {
    final headers = error.response?.headers;
    if (headers == null) return null;
    final value = headers.value('x-error-code');
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Extrait le message lisible d'une réponse d'erreur, quel que soit sa forme.
  ///
  /// Le `detail` du backend est prioritaire : sans cela, le mapping générique
  /// par code HTTP écrasait des messages actionnables (« quota OpenAI
  /// épuisé… ») au profit de « Service indisponible ».
  static String? _detailMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is List) {
        final joined = detail.map((item) => item.toString()).join('\n');
        if (joined.trim().isNotEmpty) return joined;
      }
      if (detail is Map) {
        final msg = detail['message'] ?? detail['msg'] ?? detail['detail'];
        if (msg != null) return msg.toString();
      }
      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }
      final message = data['message'];
      if (message != null) return message.toString();
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    return null;
  }

  static String errorMessage(DioException error, String fallback) {
    final detail = _detailMessage(error);
    if (detail != null) return detail;

    final statusCode = error.response?.statusCode;
    switch (statusCode) {
      case 401:
        return 'Non autorisé';
      case 409:
        return 'Conflit d\'état : la ressource a déjà été modifiée.';
      case 429:
        return 'Trop de requêtes, veuillez patienter';
      case 502:
      case 503:
        return 'Service indisponible';
      default:
        return fallback;
    }
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
