import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/features/asha/data/models/asha_models.dart';
import 'package:pitpulse_mobile/features/patient_ai/data/patient_ai_engine.dart';
import 'package:pitpulse_mobile/features/patient_ai/domain/models/ai_screening_warning.dart';
import 'package:pitpulse_mobile/features/patient_ai/domain/models/ai_source_reference.dart';
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

    final hypertensiveVitals = MaternalVitalRecordModel(
      id: 'vit-2',
      pregnancyId: 'preg-101',
      pregnancyNumber: 1,
      homeVisitId: 'vis-2',
      recordedByUserId: 'asha-1',
      recordedByName: 'ASHA Anjali',
      recordedByRole: 'ASHA',
      systolicBp: 146,
      diastolicBp: 94,
      weightKg: 65.0,
      temperatureC: 37.1,
      notes: 'Elevated BP recorded.',
      recordedAt: DateTime.now().subtract(const Duration(days: 1)),
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
        userQuery: 'How is my pregnancy progressing and baby development?',
        context: context,
      );

      expect(response.text, contains('Your Pregnancy Journey & Progress'));
      expect(response.text, contains('20 weeks 0 days'));
      expect(response.text, contains('2nd Trimester'));
      expect(response.sources.isNotEmpty, isTrue);
      expect(response.sources.any((s) => s.type == AiSourceType.pregnancyRecord), isTrue);
    });

    test('Correctly identifies empty pregnancy status truthfully', () {
      const emptyContext = PatientAiContext(
        patientName: 'Sunita M',
        healthRecordNumber: 'HR-2026-0002',
        activePregnancy: null,
        vitals: [],
        homeVisits: [],
        assignedAshaName: null,
      );

      final response = engine.processQuery(
        userQuery: 'What week am I in and when is my due date?',
        context: emptyContext,
      );

      expect(response.text, contains('do not have an active pregnancy record'));
      expect(response.sources.isEmpty, isTrue);
    });

    test('Explains recorded vitals and detects normal ranges', () {
      final context = PatientAiContext(
        patientName: 'Kavitha R',
        healthRecordNumber: 'HR-2026-0001',
        activePregnancy: testPregnancy,
        vitals: [normalVitals],
        homeVisits: [testVisit],
        assignedAshaName: 'ASHA Anjali',
      );

      final response = engine.processQuery(
        userQuery: 'What are my latest vitals and blood pressure?',
        context: context,
      );

      expect(response.text, contains('118 / 76 mmHg'));
      expect(response.text, contains('62.5 kg'));
      expect(response.text, contains('Normal Maternal Blood Pressure'));
      expect(response.warning, isNull);
      expect(response.sources.any((s) => s.type == AiSourceType.maternalVitals), isTrue);
    });

    test('Detects and flags elevated blood pressure with screening alert', () {
      final context = PatientAiContext(
        patientName: 'Kavitha R',
        healthRecordNumber: 'HR-2026-0001',
        activePregnancy: testPregnancy,
        vitals: [hypertensiveVitals],
        homeVisits: [testVisit],
        assignedAshaName: 'ASHA Anjali',
      );

      final response = engine.processQuery(
        userQuery: 'Check my BP reading and vitals',
        context: context,
      );

      expect(response.text, contains('146 / 94 mmHg'));
      expect(response.warning, isNotNull);
      expect(response.warning!.severity, equals(WarningSeverity.caution));
      expect(response.warning!.title, contains('Elevated Blood Pressure Alert'));
    });

    test('Escalates emergency red flag symptoms with emergency card and urgent guidance', () {
      final context = PatientAiContext(
        patientName: 'Kavitha R',
        healthRecordNumber: 'HR-2026-0001',
        activePregnancy: testPregnancy,
        vitals: [normalVitals],
        homeVisits: [testVisit],
        assignedAshaName: 'ASHA Anjali',
      );

      final response = engine.processQuery(
        userQuery: 'I have severe vaginal bleeding and pain',
        context: context,
      );

      expect(response.text, contains('CRITICAL EMERGENCY RED ALERT'));
      expect(response.warning, isNotNull);
      expect(response.warning!.severity, equals(WarningSeverity.emergency));
    });

    test('Generates structured doctor consultation prep questions', () {
      final context = PatientAiContext(
        patientName: 'Kavitha R',
        healthRecordNumber: 'HR-2026-0001',
        activePregnancy: testPregnancy,
        vitals: [hypertensiveVitals],
        homeVisits: [testVisit],
        assignedAshaName: 'ASHA Anjali',
      );

      final response = engine.processQuery(
        userQuery: 'What questions should I ask my doctor for my appointment visit?',
        context: context,
      );

      expect(response.text, contains('Doctor Consultation Preparation Guide'));
      expect(response.text, contains('146 / 94 mmHg'));
    });

    test('Provides curated nutrition guidance without inventing facts', () {
      final context = PatientAiContext(
        patientName: 'Kavitha R',
        healthRecordNumber: 'HR-2026-0001',
        activePregnancy: testPregnancy,
        vitals: [normalVitals],
        homeVisits: [testVisit],
        assignedAshaName: 'ASHA Anjali',
      );

      final response = engine.processQuery(
        userQuery: 'What healthy food and diet should I eat during pregnancy?',
        context: context,
      );

      expect(response.text, contains('Pregnancy Diet'));
      expect(response.text, contains('Core Nutrients'));
      expect(response.sources.any((s) => s.type == AiSourceType.curatedKnowledgeBase), isTrue);
    });

    test('Explains ASHA home visits history', () {
      final context = PatientAiContext(
        patientName: 'Kavitha R',
        healthRecordNumber: 'HR-2026-0001',
        activePregnancy: testPregnancy,
        vitals: [normalVitals],
        homeVisits: [testVisit],
        assignedAshaName: 'ASHA Anjali',
      );

      final response = engine.processQuery(
        userQuery: 'Tell me about my recent ASHA worker home checkup visits',
        context: context,
      );

      expect(response.text, contains('ASHA Field Care Summary'));
      expect(response.text, contains('ASHA Anjali'));
      expect(response.text, contains('Routine 2nd Trimester Checkup'));
      expect(response.sources.any((s) => s.type == AiSourceType.ashaHomeVisit), isTrue);
    });

    test('Handles out-of-scope queries gracefully with safety guidance', () {
      final context = PatientAiContext(
        patientName: 'Kavitha R',
        healthRecordNumber: 'HR-2026-0001',
        activePregnancy: testPregnancy,
        vitals: [normalVitals],
        homeVisits: [testVisit],
        assignedAshaName: 'ASHA Anjali',
      );

      final response = engine.processQuery(
        userQuery: 'Can you write python code for blockchain?',
        context: context,
      );

      expect(response.text, equals('I cannot answer that.'));
    });
  });
}
