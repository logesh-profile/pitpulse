import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/features/asha/data/models/asha_models.dart';
import 'package:pitpulse_mobile/features/patient_ai/domain/models/patient_ai_context.dart';
import 'package:pitpulse_mobile/features/patient_ai/presentation/screens/patient_ai_chat_screen.dart';
import 'package:pitpulse_mobile/features/pregnancy/data/models/pregnancy_model.dart';

void main() {
  group('PatientAiChatScreen Widget Tests', () {
    final testPregnancy = PregnancyModel(
      id: 'preg-101',
      patientId: 'pat-1',
      pregnancyNumber: 1,
      status: 'ACTIVE',
      lmp: DateTime.now().subtract(const Duration(days: 140)),
      edd: DateTime.now().add(const Duration(days: 140)),
      gestationalAgeWeeks: 20,
      gestationalAgeDays: 0,
      gestationalAgeDisplay: '20 weeks 0 days',
      trimester: 2,
      trimesterDisplay: '2nd Trimester',
      notes: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testVitals = MaternalVitalRecordModel(
      id: 'vit-1',
      pregnancyId: 'preg-101',
      pregnancyNumber: 1,
      homeVisitId: 'vis-1',
      recordedByUserId: 'asha-1',
      recordedByName: 'ASHA Anjali',
      recordedByRole: 'ASHA',
      systolicBp: 120,
      diastolicBp: 80,
      weightKg: 60.0,
      temperatureC: 37.0,
      recordedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final testVisit = HomeVisitModel(
      id: 'vis-1',
      patientId: 'pat-1',
      patientName: 'Kavitha R',
      ashaWorkerId: 'asha-1',
      ashaWorkerName: 'ASHA Anjali',
      visitDate: DateTime.now(),
      status: 'COMPLETED',
      purpose: 'Monthly Checkup',
      followUpRequired: false,
      createdAt: DateTime.now(),
    );

    final mockContext = PatientAiContext(
      patientName: 'Kavitha R',
      healthRecordNumber: 'HR-2026-0001',
      activePregnancy: testPregnancy,
      vitals: [testVitals],
      homeVisits: [testVisit],
      assignedAshaName: 'ASHA Anjali',
    );

    testWidgets('Renders chat screen with MAATRA Grok branding and welcome message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: PatientAiChatScreen(contextSnapshot: mockContext),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Anu'), findsOneWidget);
      expect(find.text('ur ai at ur place'), findsOneWidget);
      expect(find.textContaining('Hello Kavitha R'), findsOneWidget);
      expect(find.text('How is my baby growing this week?'), findsWidgets);
    });

    testWidgets('Tapping prompt chip sends message and generates AI response', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: PatientAiChatScreen(contextSnapshot: mockContext),
        ),
      );
      await tester.pumpAndSettle();

      final chip = find.text('How is my baby growing this week?').first;
      expect(chip, findsOneWidget);
      await tester.tap(chip);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(PatientAiChatScreen), findsOneWidget);
    });

    testWidgets('Typing custom text and sending generates grounded response', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: PatientAiChatScreen(contextSnapshot: mockContext),
        ),
      );
      await tester.pumpAndSettle();

      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);

      await tester.enterText(inputField, 'What are my latest vitals?');
      final sendButton = find.byKey(const Key('patient_ai_send_button'));
      expect(sendButton, findsOneWidget);

      await tester.tap(sendButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.textContaining('120/80 mmHg'), findsOneWidget);
    });
  });
}
