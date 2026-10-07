import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/features/asha/data/models/asha_models.dart';
import 'package:pitpulse_mobile/features/patient_ai/data/patient_ai_engine.dart';
import 'package:pitpulse_mobile/features/patient_ai/domain/models/ai_screening_warning.dart';
import 'package:pitpulse_mobile/features/patient_ai/domain/models/patient_ai_context.dart';
import 'package:pitpulse_mobile/features/pregnancy/data/models/pregnancy_model.dart';

void main() {
  group('PatientAiEngine Tests', () {
    late PatientAiEngine engine;

    setUp(() {
      engine = PatientAiEngine();
    });

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

    final normalVitals = MaternalVitalRecordModel(
      id: 'vit-1',
      pregnancyId: 'preg-101',
      pregnancyNumber: 1,
      homeVisitId: 'vis-1',
      recordedByUserId: 'asha-1',
      recordedByName: 'ASHA Anjali',
      recordedByRole: 'ASHA',
      systolicBp: 118,
      diastolicBp: 76,
      weightKg: 62.5,
      temperatureC: 36.8,
      notes: 'Patient feels well.',
      recordedAt: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now(),
    );

    final testVisit = HomeVisitModel(
      id: 'vis-1',
      patientId: 'pat-1',
      patientName: 'Kavitha R',
      ashaWorkerId: 'asha-1',
      ashaWorkerName: 'ASHA Anjali',
      visitDate: DateTime.now().subtract(const Duration(days: 3)),
      status: 'COMPLETED',
      purpose: 'Routine 2nd Trimester Checkup',
      observations: 'Fetal heart sound clear. Nutritional advice given.',
      followUpRequired: false,
      createdAt: DateTime.now(),
    );

    test('Explains active pregnancy status grounded in patient data', () {
      final context = PatientAiContext(
        patientName: 'Kavitha R',
        healthRecordNumber: 'HR-2026-0001',
        activePregnancy: testPregnancy,
        vitals: [normalVitals],
        homeVisits: [testVisit],
        assignedAshaName: 'ASHA Anjali',
      );

      final response = engine.processQuery(
        userQuery: 'Tell me about my pregnancy and EDD',
        context: context,
      );

      expect(response.text, contains('Registered Pregnancy Profile'));
      expect(response.text, contains('20 weeks 0 days'));
      expect(response.text, contains('2nd Trimester'));
    });

    test('Correctly identifies empty pregnancy status truthfully with zero fake data', () {
      const context = PatientAiContext(
        patientName: 'Deepa S',
        activePregnancy: null,
      );

      final response = engine.processQuery(
        userQuery: 'What is my pregnancy status?',
        context: context,
      );

      expect(response.text, contains('do not have an active pregnancy record'));
    });

    test('Explains recorded vitals truthfully from real patient profile', () {
      final context = PatientAiContext(
        patientName: 'Kavitha R',
        vitals: [normalVitals],
      );

      final response = engine.processQuery(
        userQuery: 'What was my last BP and vitals?',
        context: context,
      );

      expect(response.text, contains('118/76 mmHg'));
      expect(response.text, contains('ASHA Anjali'));
    });

    test('Escalates emergency red flag symptoms with emergency card and urgent guidance', () {
      const context = PatientAiContext(patientName: 'Kavitha R');

      final response = engine.processQuery(
        userQuery: 'I have severe bleeding right now!',
        context: context,
      );

      expect(response.warning, isNotNull);
      expect(response.warning!.severity, WarningSeverity.emergency);
      expect(response.text, contains('108'));
    });

    test('Handles natural everyday conversation like ChatGPT/Grok', () {
      const context = PatientAiContext(patientName: 'Kavitha R');

      final response = engine.processQuery(
        userQuery: 'helo',
        context: context,
      );

      expect(response.text, contains('Hello Kavitha R!'));
      expect(response.text, contains('MAATRA'));
    });

    test('Provides comprehensive medical remedies for temperature/fever', () {
      const context = PatientAiContext(patientName: 'Kavitha R');

      final response = engine.processQuery(
        userQuery: 'temperature today?',
        context: context,
      );

      expect(response.text, contains('98.6°F'));
      expect(response.text, contains('Hydration'));
      expect(response.text, contains('Home Care'));
    });

    test('Provides home remedies for headache', () {
      const context = PatientAiContext(patientName: 'Kavitha R');

      final response = engine.processQuery(
        userQuery: 'I have a bad headache, any home remedies?',
        context: context,
      );

      expect(response.text, contains('Headache Relief'));
      expect(response.text, contains('Hydration'));
    });

    test('Explains ASHA home visits history truthfully', () {
      final context = PatientAiContext(
        patientName: 'Kavitha R',
        homeVisits: [testVisit],
      );

      final response = engine.processQuery(
        userQuery: 'What was my last visit checkup?',
        context: context,
      );

      expect(response.text, contains('Recent Home / Field Visit'));
      expect(response.text, contains('Routine 2nd Trimester Checkup'));
      expect(response.text, contains('ASHA Anjali'));
    });
  });
}
