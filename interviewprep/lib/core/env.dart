class Env {
  static const String _rawApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String backendApiKey = String.fromEnvironment(
    'BACKEND_API_KEY',
  );

  static String get apiBaseUrl {
    return requireApiBaseUrl(_rawApiBaseUrl);
  }

  static String requireApiBaseUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      throw StateError(
        'API_BASE_URL must be provided with --dart-define=API_BASE_URL=...',
      );
    }
    return value.endsWith('/')
        ? value.substring(0, value.length - 1)
        : value;
  }
}
