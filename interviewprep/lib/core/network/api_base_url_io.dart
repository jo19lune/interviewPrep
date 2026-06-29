import 'dart:io';

String defaultApiBaseUrl() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:9000';
  }
  return 'http://192.168.88.134:9000';
}
