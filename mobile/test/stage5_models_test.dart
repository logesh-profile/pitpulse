import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/features/asha/data/models/asha_models.dart';

void main() {
  group('Stage 5 Data Models Deserialization & Formatting', () {
    test('AshaAssignmentModel correctly deserializes from JSON', () {
      final json = {
        'id': '11111111-2222-3333-4444-555555555555',
        'patient_id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        'patient_name': 'Meera Devi',
        'patient_email': 'meera@village.in',
        'patient_phone': '+919876543210',
        'health_record_number': 'HR-2026-MEERA',
        'has_active_pregnancy': true,
        'pregnancy_id': 'pppppppp-qqqq-rrrr-ssss-tttttttttttt',
        'pregnancy_number': 1,
        'last_visit_date': '2026-10-01T10:00:00Z',
        'total_visits': 2,
        'asha_worker_id': 'wwwwwwww-xxxx-yyyy-zzzz-1234567890ab',
        'asha_worker_name': 'Sunita Bai',
        'status': 'ACTIVE',
        'assigned_at': '2026-09-01T08:00:00Z',
        'unassigned_at': null,
        'notes': 'Sector 3 maternal care assignment',
      };

      final model = AshaAssignmentModel.fromJson(json);

      expect(model.id, '11111111-2222-3333-4444-555555555555');
      expect(model.patientId, 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
      expect(model.patientName, 'Meera Devi');
      expect(model.hasActivePregnancy, isTrue);
      expect(model.pregnancyNumber, 1);
      expect(model.totalVisits, 2);
      expect(model.ashaWorkerName, 'Sunita Bai');
      expect(model.status, 'ACTIVE');
      expect(model.notes, 'Sector 3 maternal care assignment');
    });

    test('HomeVisitModel correctly deserializes from JSON', () {
      final json = {
        'id': 'vvvvvvvv-1111-2222-3333-444444444444',
        'patient_id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        'patient_name': 'Meera Devi',
        'patient_health_record_number': 'HR-2026-MEERA',
        'pregnancy_id': 'pppppppp-qqqq-rrrr-ssss-tttttttttttt',
        'pregnancy_number': 1,
        'asha_worker_id': 'wwwwwwww-xxxx-yyyy-zzzz-1234567890ab',
        'asha_worker_name': 'Sunita Bai',
        'visit_date': '2026-10-04',
        'started_at': '2026-10-04T09:30:00Z',
        'completed_at': '2026-10-04T10:00:00Z',
        'status': 'COMPLETED',
        'purpose': 'Routine 1st Trimester Field Checkup',
        'observations': 'Patient reports normal appetite and good rest.',
        'notes': 'Supplements given.',
        'follow_up_required': true,
        'follow_up_notes': 'Check BP again in 2 weeks.',
        'created_at': '2026-10-04T10:00:00Z',
      };

      final model = HomeVisitModel.fromJson(json);

      expect(model.id, 'vvvvvvvv-1111-2222-3333-444444444444');
      expect(model.patientName, 'Meera Devi');
      expect(model.status, 'COMPLETED');
      expect(model.purpose, 'Routine 1st Trimester Field Checkup');
      expect(model.followUpRequired, isTrue);
      expect(model.followUpNotes, 'Check BP again in 2 weeks.');
    });

    test('MaternalVitalRecordModel correctly formats BP, Weight, and Temperature', () {
      final json = {
        'id': 'mmmmmmmm-1111-2222-3333-444444444444',
        'pregnancy_id': 'pppppppp-qqqq-rrrr-ssss-tttttttttttt',
        'pregnancy_number': 1,
        'home_visit_id': 'vvvvvvvv-1111-2222-3333-444444444444',
        'recorded_by_user_id': 'uuuuuuuu-1111-2222-3333-444444444444',
        'recorded_by_name': 'Sunita Bai',
        'recorded_by_role': 'ASHA',
        'recorded_at': '2026-10-04T10:05:00Z',
        'systolic_bp': 118,
        'diastolic_bp': 76,
        'weight_kg': 62.4,
        'temperature_c': 36.7,
        'notes': 'Seated resting measurement',
        'created_at': '2026-10-04T10:05:00Z',
      };

      final model = MaternalVitalRecordModel.fromJson(json);

      expect(model.systolicBp, 118);
      expect(model.diastolicBp, 76);
      expect(model.bpDisplay, '118 / 76 mmHg');
      expect(model.weightDisplay, '62.4 kg');
      expect(model.temperatureDisplay, '36.7 °C');
      expect(model.recordedByRole, 'ASHA');
      expect(model.recordedByName, 'Sunita Bai');
    });

    test('MaternalVitalRecordModel handles partial/null observations cleanly', () {
      final json = {
        'id': 'mmmmmmmm-2222-3333-4444-555555555555',
        'pregnancy_id': 'pppppppp-qqqq-rrrr-ssss-tttttttttttt',
        'recorded_by_user_id': 'uuuuuuuu-1111-2222-3333-444444444444',
        'recorded_at': '2026-10-04T10:05:00Z',
        'systolic_bp': 120,
        'diastolic_bp': null,
        'weight_kg': null,
        'temperature_c': null,
      };

      final model = MaternalVitalRecordModel.fromJson(json);

      expect(model.bpDisplay, '120 mmHg (Systolic)');
      expect(model.weightDisplay, 'Not recorded');
      expect(model.temperatureDisplay, 'Not recorded');
    });
  });
}
