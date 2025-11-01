import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kora_corner/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: KoraCornerApp(),
      ),
    );

    // Verify that our app has built the MaterialApp.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
