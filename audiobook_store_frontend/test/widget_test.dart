import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audiobook_store_frontend/main.dart';

void main() {
  testWidgets('App generation message displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('audiobook_store_frontend App is being generated...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('App bar has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('audiobook_store_frontend'), findsOneWidget);
  });
}
