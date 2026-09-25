import 'package:flutter_test/flutter_test.dart';
import 'package:interviewprep/core/network/backend_warmup.dart';

void main() {
  test('builds the Render health URL outside the API v1 prefix', () {
    expect(
      BackendWarmupService.buildHealthUrl('https://api.example.com/'),
      'https://api.example.com/health',
    );
  });
}
