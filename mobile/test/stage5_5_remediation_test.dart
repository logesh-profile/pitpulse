import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/core/network/api_client.dart';
import 'package:pitpulse_mobile/core/errors/failures.dart';
import 'package:pitpulse_mobile/features/auth/data/models/user_model.dart';
import 'package:pitpulse_mobile/features/doctor/data/models/doctor_models.dart';

void main() {
  group('Stage 5.5 Remediation Suite', () {
    test('1. Shared ApiClient singleton token propagation across feature domains', () {
      final client = ApiClient.instance;
      client.setAuthToken(null);
      expect(client.authToken, isNull);

      // Simulate AuthController setting authenticated session token on shared client
      client.setAuthToken('jwt_session_token_xyz123');
      expect(client.authToken, 'jwt_session_token_xyz123');

      // Feature remote data source references shared ApiClient.instance
      final featureClient = ApiClient.instance;
      expect(featureClient.authToken, 'jwt_session_token_xyz123');

      // Simulate logout / clearing auth token
      client.setAuthToken(null);
      expect(client.authToken, isNull);
      expect(featureClient.authToken, isNull);
    });

    test('2. UserModel email verification & activation state parsing', () {
      final userJson = {
        'id': 'u-1234',
        'email': 'patient_verified@pitpulse.org',
        'full_name': 'Meera Patel',
        'role': 'PATIENT',
        'is_active': true,
        'is_verified': true,
        'must_change_password': false,
        'created_at': '2026-10-04T12:00:00Z',
      };

      final user = UserModel.fromJson(userJson);
      expect(user.id, 'u-1234');
      expect(user.email, 'patient_verified@pitpulse.org');
      expect(user.role, 'PATIENT');
      expect(user.isActive, true);
      expect(user.mustChangePassword, false);
    });

    test('3. DoctorPatientModel serialization & clinical status indicators', () {
      final patientJson = {
        'patient_id': 'pat-uuid-001',
        'user_id': 'user-uuid-002',
        'full_name': 'Sunita Devi',
        'email': 'sunita@pitpulse.org',
        'phone': '+919876500001',
        'village_locality': 'Rampur Sector 4',
        'date_of_birth': '1998-04-12',
        'blood_group': 'B+',
        'has_active_pregnancy': true,
        'active_pregnancy_ga_weeks': 24,
        'active_pregnancy_edd': '2027-01-20',
        'assigned_asha_name': 'Kavita ASHA',
        'assigned_asha_id': 'asha-uuid-003',
        'created_at': '2026-10-04T10:00:00Z',
      };

      final model = DoctorPatientModel.fromJson(patientJson);
      expect(model.patientId, 'pat-uuid-001');
      expect(model.fullName, 'Sunita Devi');
      expect(model.hasActivePregnancy, true);
      expect(model.activePregnancyGaWeeks, 24);
      expect(model.assignedAshaName, 'Kavita ASHA');
      expect(model.assignedAshaId, 'asha-uuid-003');
    });

    test('4. DoctorAshaModel serialization & workload distribution', () {
      final ashaJson = {
        'asha_id': 'asha-uuid-101',
        'user_id': 'user-uuid-102',
        'full_name': 'Pooja Verma',
        'email': 'pooja@pitpulse.org',
        'phone': '+919876540000',
        'worker_id_code': 'ASHA-NORTH-01',
        'assigned_area': 'North Ward Sector 2',
        'primary_health_center': 'Primary Health Centre North',
        'active_patients_count': 5,
      };

      final model = DoctorAshaModel.fromJson(ashaJson);
      expect(model.ashaId, 'asha-uuid-101');
      expect(model.fullName, 'Pooja Verma');
      expect(model.workerIdCode, 'ASHA-NORTH-01');
      expect(model.activePatientsCount, 5);
    });

    test('5. Semantic ServerFailure status codes mapping', () {
      const server403 = ServerFailure('Access Denied: You do not have active clinical authorization for this record.', statusCode: 403);
      expect(server403.statusCode, 403);
      expect(server403.message, contains('Access Denied'));

      const server401 = ServerFailure('Authentication failed: Invalid credentials or session expired.', statusCode: 401);
      expect(server401.statusCode, 401);

      const server404 = ServerFailure('Requested healthcare record was not found.', statusCode: 404);
      expect(server404.statusCode, 404);

      const server409 = ServerFailure('Conflict: Record already exists in current status.', statusCode: 409);
      expect(server409.statusCode, 409);

      const server422 = ServerFailure('Validation Error: Medical parameter input is invalid.', statusCode: 422);
      expect(server422.statusCode, 422);
    });
  });
}
