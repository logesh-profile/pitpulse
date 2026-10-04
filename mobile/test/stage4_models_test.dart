import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/features/pregnancy/data/models/pregnancy_model.dart';

void main() {
  group('PregnancyModel Serialization & Logic', () {
    final sampleJson = {
      'id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
      'patient_id': '98765432-abcd-ef01-2345-6789abcdef01',
      'pregnancy_number': 1,
      'status': 'ACTIVE',
      'lmp': '2026-01-01',
      'edd': '2026-10-08',
      'gestational_age_weeks': 10,
      'gestational_age_days': 3,
      'gestational_age_display': '10 weeks 3 days',
      'trimester': 1,
      'trimester_display': '1st Trimester',
      'notes': 'Initial baseline maternal notes',
      'created_at': '2026-01-15T10:30:00Z',
      'updated_at': '2026-01-15T10:30:00Z',
    };

    test('correctly deserializes from valid backend pregnancy JSON payload', () {
      final model = PregnancyModel.fromJson(sampleJson);

      expect(model.id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(model.patientId, '98765432-abcd-ef01-2345-6789abcdef01');
      expect(model.pregnancyNumber, 1);
      expect(model.status, 'ACTIVE');
      expect(model.isActive, isTrue);
      expect(model.lmp, DateTime.parse('2026-01-01'));
      expect(model.edd, DateTime.parse('2026-10-08'));
      expect(model.gestationalAgeWeeks, 10);
      expect(model.gestationalAgeDays, 3);
      expect(model.gestationalAgeDisplay, '10 weeks 3 days');
      expect(model.trimester, 1);
      expect(model.trimesterDisplay, '1st Trimester');
      expect(model.notes, 'Initial baseline maternal notes');
    });

    test('serializes back to JSON map matching backend contract', () {
      final model = PregnancyModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['id'], 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(json['pregnancy_number'], 1);
      expect(json['status'], 'ACTIVE');
      expect(json['lmp'], '2026-01-01');
      expect(json['edd'], '2026-10-08');
      expect(json['gestational_age_weeks'], 10);
      expect(json['gestational_age_days'], 3);
      expect(json['trimester'], 1);
    });

    test('isActive returns false when status is COMPLETED or TERMINATED', () {
      final completedJson = Map<String, dynamic>.from(sampleJson)..['status'] = 'COMPLETED';
      final model = PregnancyModel.fromJson(completedJson);
      expect(model.isActive, isFalse);
    });
  });
}
