import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/features/admin/data/models/professional_user_model.dart';
import 'package:pitpulse_mobile/features/patients/data/models/patient_profile_model.dart';

void main() {
  group('Stage 3 Domain Models Suite', () {
    test('PatientProfileModel and HealthRecordModel serialization and deserialization', () {
      final json = {
        'id': 'profile-123',
        'user_id': 'user-456',
        'full_name': 'Ravi Kumar',
        'email': 'ravi@pitpulse.org',
        'phone': '+919876543210',
        'date_of_birth': '1990-05-20',
        'sex': 'MALE',
        'address': '123 Main Street',
        'village_locality': 'Rampur',
        'emergency_contact_name': 'Sita Devi',
        'emergency_contact_phone': '+919876543211',
        'blood_group': 'B+',
        'baseline_health_info': 'Hypertension diagnosed in 2024',
        'health_record': {
          'id': 'hr-789',
          'record_number': 'HR-B82A-C4F1',
          'created_at': '2026-10-04T10:00:00Z',
        },
        'created_at': '2026-10-04T10:00:00Z',
        'updated_at': '2026-10-04T10:00:00Z',
      };

      final model = PatientProfileModel.fromJson(json);

      expect(model.id, 'profile-123');
      expect(model.userId, 'user-456');
      expect(model.fullName, 'Ravi Kumar');
      expect(model.bloodGroup, 'B+');
      expect(model.healthRecord?.recordNumber, 'HR-B82A-C4F1');

      final serialized = model.toJson();
      expect(serialized['emergency_contact_name'], 'Sita Devi');
      expect(serialized['village_locality'], 'Rampur');
    });

    test('ProfessionalUserModel and ProvisionedAccountResult parsing', () {
      final json = {
        'user_id': 'user-doc-1',
        'email': 'doctor@pitpulse.org',
        'full_name': 'Dr. Ananya Sharma',
        'phone': '+919988776655',
        'role': 'DOCTOR',
        'temporary_password': 'TempPass123!@#',
        'must_change_password': true,
        'medical_license_number': 'MCI-99881',
      };

      final result = ProvisionedAccountResult.fromJson(json);
      expect(result.userId, 'user-doc-1');
      expect(result.role, 'DOCTOR');
      expect(result.temporaryPassword, 'TempPass123!@#');
      expect(result.mustChangePassword, true);
    });
  });
}
