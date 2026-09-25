import 'package:dio/dio.dart';

import '../env.dart';

class BackendWarmupService {
  BackendWarmupService({Dio? client}) : _client = client;

  static const Duration defaultTimeout = Duration(seconds: 62);

  final Dio? _client;

  String get healthUrl => buildHealthUrl(Env.apiBaseUrl);

  static String buildHealthUrl(String baseUrl) {
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return '$normalized/health';
  }

  Future<void> waitUntilReady({Duration timeout = defaultTimeout}) async {
    final client =
        _client ??
        Dio(
          BaseOptions(
            baseUrl: Env.apiBaseUrl,
            connectTimeout: timeout,
            receiveTimeout: timeout,
            sendTimeout: timeout,
          ),
        );

    if (_client == null && Env.backendApiKey.isNotEmpty) {
      client.options.headers['X-API-Key'] = Env.backendApiKey;
    }

    try {
      await client.get<void>(
        '/health',
        options: Options(receiveTimeout: timeout, sendTimeout: timeout),
      );
    } on DioException {
      // A cold or unavailable backend must not prevent the app from opening.
    }
  }
}
