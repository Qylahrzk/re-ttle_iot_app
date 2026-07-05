// This is a basic Flutter widget test for Re:ttle Eco Rewards components.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rettle_eco_rewards/screens/scan_screen.dart';

void main() {
  testWidgets('ScanningLineEffect renders successfully', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ScanningLineEffect())),
    );

    // Verify that our ScanningLineEffect widget is present in the tree.
    expect(find.byType(ScanningLineEffect), findsOneWidget);
  });
}
