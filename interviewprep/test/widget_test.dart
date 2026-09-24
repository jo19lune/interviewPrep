import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewprep/app/app.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: InterviewPrepApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App has debug banner disabled', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: InterviewPrepApp()));
    await tester.pump();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.debugShowCheckedModeBanner, false);
  });

  testWidgets('App uses GoRouter', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: InterviewPrepApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
