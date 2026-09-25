import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interviewprep/core/utils/app_dialog.dart';
import 'package:interviewprep/core/network/api_client.dart';

void main() {
  test('classifies connection failures as connectivity errors', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      type: DioExceptionType.connectionError,
    );

    expect(AppDialog.isConnectivityError(error), isTrue);
  });

  test('does not classify HTTP errors as missing Internet', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 401,
      ),
    );

    expect(AppDialog.isConnectivityError(error), isFalse);
  });

  for (final entry in <MapEntry<int, String>>[
    const MapEntry(401, 'Non autorisé'),
    const MapEntry(429, 'Trop de requêtes, veuillez patienter'),
    const MapEntry(503, 'Service indisponible'),
  ]) {
    test('keeps HTTP ${entry.key} as a backend message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: entry.key,
        ),
      );

      expect(ApiClient.errorMessage(error, 'Erreur'), entry.value);
      expect(AppDialog.isConnectivityError(error), isFalse);
    });
  }

  testWidgets('renders an error dialog and closes through its action', (
    WidgetTester tester,
  ) async {
    var confirmed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AppDialog.error(
              context,
              title: 'Erreur de test',
              message: 'Message de test',
              buttonText: 'Fermer',
              onConfirm: () => confirmed = true,
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text('Erreur de test'), findsOneWidget);
    expect(find.text('Message de test'), findsOneWidget);

    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
    expect(find.text('Erreur de test'), findsNothing);
  });
}
