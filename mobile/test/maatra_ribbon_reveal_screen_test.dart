import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/features/common/presentation/screens/maatra_ribbon_reveal_screen.dart';

void main() {
  group('MaatraRibbonRevealScreen Widget Tests', () {
    testWidgets('Renders ribbon loop logo and MAATRA wordmark', (WidgetTester tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MaatraRibbonRevealScreen(
            onCompleted: () {
              completed = true;
            },
          ),
        ),
      );

      // Initial state
      expect(find.text('MAATRA'), findsOneWidget);
      expect(find.text('INTELLIGENT HEALTH & MATERNAL WELLNESS'), findsOneWidget);

      // Pump through all animations and delayed sequence
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });
  });
}
