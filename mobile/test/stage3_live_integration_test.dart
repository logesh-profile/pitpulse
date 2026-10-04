import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/core/network/api_client.dart';
import 'package:pitpulse_mobile/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:pitpulse_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pitpulse_mobile/features/patients/data/datasources/patient_remote_data_source.dart';

void main() {
  test('STAGE 3 LIVE INTEGRATION TEST: Full Admin Provisioning + Activation + Patient Profile against real FastAPI + PostgreSQL', () async {
    final client = ApiClient(baseUrl: 'http://127.0.0.1:8000');
    final authDataSource = AuthRemoteDataSourceImpl(apiClient: client);
    final adminDataSource = AdminRemoteDataSourceImpl(apiClient: client);
    final patientDataSource = PatientRemoteDataSourceImpl(apiClient: client);

    final randomSuffix = Random().nextInt(1000000).toString();

    // 1. Authenticate as Admin
    final adminLogin = await authDataSource.login(
      email: 'admin@pitpulse.org',
      password: 'logesh@360',
    );
    expect(adminLogin.user.role, 'ADMIN');
    client.setAuthToken(adminLogin.accessToken);

    // 2. Admin provisions Doctor
    final docEmail = 'live_doc_$randomSuffix@pitpulse.org';
    final docProvision = await adminDataSource.createDoctor(
      email: docEmail,
      fullName: 'Dr. Live Doctor',
      medicalLicenseNumber: 'MCI-LIVE-$randomSuffix',
      specialization: 'General Medicine',
    );
    expect(docProvision.role, 'DOCTOR');
    expect(docProvision.mustChangePassword, true);
    expect(docProvision.temporaryPassword, isNotEmpty);

    // 3. Admin provisions ASHA
    final ashaEmail = 'live_asha_$randomSuffix@pitpulse.org';
    final ashaProvision = await adminDataSource.createAsha(
      email: ashaEmail,
      fullName: 'Live ASHA Worker',
      workerIdCode: 'ASHA-LIVE-$randomSuffix',
      assignedArea: 'Ward 10 South',
    );
    expect(ashaProvision.role, 'ASHA');
    expect(ashaProvision.mustChangePassword, true);

    // 4. Admin lists professionals
    final professionals = await adminDataSource.listProfessionals();
    expect(professionals.any((p) => p.email == docEmail), true);
    expect(professionals.any((p) => p.email == ashaEmail), true);

    // 5. Doctor logs in with temporary password
    final docLogin = await authDataSource.login(
      email: docEmail,
      password: docProvision.temporaryPassword,
    );
    expect(docLogin.user.mustChangePassword, true);
    client.setAuthToken(docLogin.accessToken);

    // 6. Doctor activates account by changing password
    const newDocPassword = 'NewPermanentDocPass2026!';
    final activatedDoc = await authDataSource.changePassword(
      currentPassword: docProvision.temporaryPassword,
      newPassword: newDocPassword,
    );
    expect(activatedDoc.user.mustChangePassword, false);

    // 7. Patient registration and profile management
    final patientEmail = 'live_patient_$randomSuffix@pitpulse.org';
    const patientPassword = 'PatientSecretPass123!';
    await authDataSource.register(
      email: patientEmail,
      password: patientPassword,
      fullName: 'Live Patient Test',
    );

    final patientLogin = await authDataSource.login(
      email: patientEmail,
      password: patientPassword,
    );
    expect(patientLogin.user.role, 'PATIENT');
    client.setAuthToken(patientLogin.accessToken);

    // 8. Patient gets profile (auto-initialized with Health Record)
    final profile = await patientDataSource.getMyProfile();
    expect(profile.email, patientEmail);
    expect(profile.healthRecord, isNotNull);
    expect(profile.healthRecord!.recordNumber.startsWith('HR-'), true);

    // 9. Patient updates profile
    final updatedProfile = await patientDataSource.updateMyProfile(
      dateOfBirth: '1992-08-24',
      sex: 'MALE',
      bloodGroup: 'AB+',
      villageLocality: 'Sundar Nagar',
      emergencyContactName: 'Geeta Devi',
      emergencyContactPhone: '+919876500000',
    );
    expect(updatedProfile.dateOfBirth, '1992-08-24');
    expect(updatedProfile.bloodGroup, 'AB+');
    expect(updatedProfile.villageLocality, 'Sundar Nagar');
  });
}
