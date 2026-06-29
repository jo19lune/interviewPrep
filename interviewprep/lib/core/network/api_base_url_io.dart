import 'dart:io';

String defaultApiBaseUrl() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:9000';
  }
  return 'http://localhost:9000';
}
