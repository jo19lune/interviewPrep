import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_base_url_stub.dart'
    if (dart.library.io) 'api_base_url_io.dart'
    if (dart.library.html) 'api_base_url_web.dart';

class ApiClient {
  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static String get baseUrl => _configuredBaseUrl.isNotEmpty ? _configuredBaseUrl : defaultApiBaseUrl();

  final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio _refreshDio;

  ApiClient() : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 && e.requestOptions.path != '/auth/refresh') {
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

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
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
