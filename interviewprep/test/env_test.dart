import 'package:flutter_test/flutter_test.dart';
import 'package:interviewprep/core/env.dart';

void main() {
  test('requires an API base URL', () {
    expect(
      () => Env.requireApiBaseUrl(''),
      throwsA(isA<StateError>()),
    );
  });

  test('removes trailing slash from the API base URL', () {
    expect(
      Env.requireApiBaseUrl(' https://api.example.com/ '),
      'https://api.example.com',
    );
  });
}
