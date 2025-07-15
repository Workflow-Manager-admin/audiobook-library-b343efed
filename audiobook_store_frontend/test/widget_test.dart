import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audiobook_store_frontend/main.dart';

void main() {
  testWidgets('AudiobookStoreApp builds and shows CircularProgressIndicator', (WidgetTester tester) async {
    await tester.pumpWidget(const AudiobookStoreApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
