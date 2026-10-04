import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/core/network/api_client.dart';
import 'package:pitpulse_mobile/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:pitpulse_mobile/features/asha/data/datasources/asha_remote_data_source.dart';
import 'package:pitpulse_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pitpulse_mobile/features/patients/data/datasources/patient_remote_data_source.dart';
import 'package:pitpulse_mobile/features/pregnancy/data/datasources/pregnancy_remote_data_source.dart';

void main() {
  group('STAGE 5 LIVE INTEGRATION TEST: Full ASHA Assignment + Home Visit + Maternal Vitals Flow', () {
    late ApiClient apiClient;
    late AuthRemoteDataSource authDataSource;
    late AdminRemoteDataSource adminDataSource;
    late AshaRemoteDataSource ashaDataSource;
    late PatientRemoteDataSource patientDataSource;
    late PregnancyRemoteDataSource pregnancyDataSource;

    setUp(() {
      apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000');
      authDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
      adminDataSource = AdminRemoteDataSourceImpl(apiClient: apiClient);
      ashaDataSource = AshaRemoteDataSource(apiClient: apiClient);
      patientDataSource = PatientRemoteDataSourceImpl(apiClient: apiClient);
      pregnancyDataSource = PregnancyRemoteDataSource(apiClient: apiClient);
    });

    test('End-to-End Field Care Workflow: Admin Assign -> ASHA View -> Home Visit -> Vitals -> Patient View', () async {
      final rand = Random().nextInt(999999);

      // ==========================================
      // Step 1: Admin Login & Provision ASHA 1 & 2
      // ==========================================
      final adminLogin = await authDataSource.login(
        email: 'admin@pitpulse.org',
        password: 'logesh@360',
      );
      expect(adminLogin.accessToken.isNotEmpty, isTrue);
      apiClient.setAuthToken(adminLogin.accessToken);

      final asha1Email = 'asha_field_${rand}_1@pitpulse.org';
      final asha1Prov = await adminDataSource.createAsha(
        email: asha1Email,
        fullName: 'ASHA Field Worker 1',
        workerIdCode: 'ASHA-F$rand',
        assignedArea: 'East Sector $rand',
        primaryHealthCenter: 'Primary Health Center A',
      );

      final asha2Email = 'asha_field_${rand}_2@pitpulse.org';
      final asha2Prov = await adminDataSource.createAsha(
        email: asha2Email,
        fullName: 'ASHA Field Worker 2',
        workerIdCode: 'ASHA-G$rand',
        assignedArea: 'West Sector $rand',
        primaryHealthCenter: 'Primary Health Center B',
      );

      // ==========================================
      // Step 2: Patient Registration & Pregnancy
      // ==========================================
      final patEmail = 'pat_maternal_$rand@pitpulse.org';
      const patPassword = 'Password123!';
      final patientUser = await authDataSource.register(
        email: patEmail,
        password: patPassword,
        fullName: 'Ananya Sharma',
      );
      expect(patientUser.email, patEmail);

      final patLogin = await authDataSource.login(email: patEmail, password: patPassword);
      apiClient.setAuthToken(patLogin.accessToken);

      final patProfile = await patientDataSource.getMyProfile();
      final patProfileId = patProfile.id;

      // Patient creates pregnancy record
      final lmp = DateTime.now().subtract(const Duration(days: 60));
      final preg = await pregnancyDataSource.createPregnancy(lmp: lmp);
      expect(preg.status, 'ACTIVE');

      // ==========================================
      // Step 3: Admin Assigns Patient to ASHA 1
      // ==========================================
      apiClient.setAuthToken(adminLogin.accessToken);

      // Find asha1 profile id
      final ashasList = await ashaDataSource.getAdminAshaWorkersList();
      final asha1Record = ashasList.firstWhere((a) => (a['user']?['email'] == asha1Email));
      final asha1ProfileId = asha1Record['id'] as String;


      final assignment = await ashaDataSource.assignPatientToAsha(
        ashaWorkerId: asha1ProfileId,
        patientId: patProfileId,
        notes: 'Initial allocation for maternity care.',
      );
      expect(assignment.status, 'ACTIVE');
      expect(assignment.patientId, patProfileId);
      expect(assignment.ashaWorkerId, asha1ProfileId);

      // ==========================================
      // Step 4: ASHA 1 Logs In & Views Patient
      // ==========================================
      final asha1Login = await authDataSource.login(
        email: asha1Email,
        password: asha1Prov.temporaryPassword,
      );
      apiClient.setAuthToken(asha1Login.accessToken);

      final assignedPatients = await ashaDataSource.getMyAssignedPatients();
      expect(assignedPatients.length, 1);
      expect(assignedPatients.first.patientId, patProfileId);
      expect(assignedPatients.first.hasActivePregnancy, isTrue);

      // ==========================================
      // Step 5: ASHA 1 Records Home Visit & Vitals
      // ==========================================
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final homeVisit = await ashaDataSource.createHomeVisit(
        patientId: patProfileId,
        visitDate: todayStr,
        pregnancyId: preg.id,
        purpose: 'Routine Prenatal Field Checkup',
        observations: 'Patient in good spirits, taking iron/folic acid tablets.',
        followUpRequired: true,
        followUpNotes: 'Check weight and BP in 2 weeks.',
      );
      expect(homeVisit.status, 'COMPLETED');
      expect(homeVisit.purpose, 'Routine Prenatal Field Checkup');

      final vital = await ashaDataSource.recordVitals(
        patientId: patProfileId,
        visitId: homeVisit.id,
        systolicBp: 118,
        diastolicBp: 76,
        weightKg: 62.4,
        temperatureC: 36.7,
        notes: 'Resting seated observation.',
      );
      expect(vital.systolicBp, 118);
      expect(vital.diastolicBp, 76);
      expect(vital.weightKg, 62.4);
      expect(vital.temperatureC, 36.7);
      expect(vital.recordedByRole, 'ASHA');

      // ==========================================
      // Step 6: Patient Logs In & Views Visit + Vitals
      // ==========================================
      apiClient.setAuthToken(patLogin.accessToken);

      final patAsha = await ashaDataSource.getMyAshaAssignment();
      expect(patAsha, isNotNull);
      expect(patAsha!.ashaWorkerId, asha1ProfileId);

      final patVisits = await ashaDataSource.getMyHomeVisits();
      expect(patVisits.length, 1);
      expect(patVisits.first.id, homeVisit.id);

      final patVitals = await ashaDataSource.getMyVitals();
      expect(patVitals.length, 1);
      expect(patVitals.first.systolicBp, 118);
      expect(patVitals.first.bpDisplay, '118 / 76 mmHg');

      // ==========================================
      // Step 7: ASHA 2 Logs In -> Unassigned Access Rejected
      // ==========================================
      final asha2Login = await authDataSource.login(
        email: asha2Email,
        password: asha2Prov.temporaryPassword,
      );
      apiClient.setAuthToken(asha2Login.accessToken);

      final asha2Patients = await ashaDataSource.getMyAssignedPatients();
      expect(asha2Patients.isEmpty, isTrue);

      // Attempting to access Patient 1 details directly throws 403
      expect(
        () async => await ashaDataSource.getAssignedPatientDetail(patProfileId),
        throwsA(anything),
      );
    });
  });
}
