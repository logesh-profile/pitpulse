import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../patients/data/models/patient_profile_model.dart';
import '../models/professional_user_model.dart';

abstract class AdminRemoteDataSource {
  Future<ProvisionedAccountResult> createDoctor({
    required String email,
    required String fullName,
    String? phone,
    String? medicalLicenseNumber,
    String? specialization,
    String? facilityName,
  });

  Future<ProvisionedAccountResult> createAsha({
    required String email,
    required String fullName,
    String? phone,
    String? workerIdCode,
    String? assignedArea,
    String? primaryHealthCenter,
  });

  Future<PatientProfileModel> createPatient({
    required String email,
    required String fullName,
    String? phone,
    String? password,
    String? dateOfBirth,
    String? sex,
    String? bloodGroup,
    String? address,
    String? villageLocality,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? baselineHealthInfo,
  });

  Future<List<ProfessionalUserModel>> listProfessionals();

  Future<List<PatientProfileModel>> listPatients();

  Future<bool> toggleUserStatus({
    required String userId,
    required bool isActive,
  });

  Future<bool> deleteUser({
    required String userId,
  });
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final ApiClient apiClient;

  AdminRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ProvisionedAccountResult> createDoctor({
    required String email,
    required String fullName,
    String? phone,
    String? medicalLicenseNumber,
    String? specialization,
    String? facilityName,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/api/v1/admin/users/doctors',
      data: {
        'email': email.trim(),
        'full_name': fullName.trim(),
        'phone': phone?.trim(),
        'medical_license_number': medicalLicenseNumber?.trim(),
        'specialization': specialization?.trim(),
        'facility_name': facilityName?.trim(),
      },
    );

    if (response.data != null) {
      try {
        return ProvisionedAccountResult.fromJson(response.data!);
      } catch (e) {
        throw ParsingFailure('Failed to parse doctor creation response: $e');
      }
    } else {
      throw const ParsingFailure('Empty response from /api/v1/admin/users/doctors');
    }
  }

  @override
  Future<ProvisionedAccountResult> createAsha({
    required String email,
    required String fullName,
    String? phone,
    String? workerIdCode,
    String? assignedArea,
    String? primaryHealthCenter,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/api/v1/admin/users/asha-workers',
      data: {
        'email': email.trim(),
        'full_name': fullName.trim(),
        'phone': phone?.trim(),
        'worker_id_code': workerIdCode?.trim(),
        'assigned_area': assignedArea?.trim(),
        'primary_health_center': primaryHealthCenter?.trim(),
      },
    );

    if (response.data != null) {
      try {
        return ProvisionedAccountResult.fromJson(response.data!);
      } catch (e) {
        throw ParsingFailure('Failed to parse ASHA creation response: $e');
      }
    } else {
      throw const ParsingFailure('Empty response from /api/v1/admin/users/asha-workers');
    }
  }

  @override
  Future<List<ProfessionalUserModel>> listProfessionals() async {
    final response = await apiClient.get<List<dynamic>>(
      '/api/v1/admin/users/professionals',
    );

    if (response.data != null) {
      try {
        return (response.data!)
            .map((item) => ProfessionalUserModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        throw ParsingFailure('Failed to parse professionals list: $e');
      }
    } else {
      throw const ParsingFailure('Empty response from /api/v1/admin/users/professionals');
    }
  }

  @override
  Future<bool> toggleUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    final response = await apiClient.patch<Map<String, dynamic>>(
      '/api/v1/admin/users/$userId/status',
      data: {'is_active': isActive},
    );
    return response.statusCode == 200;
  }

  @override
  Future<PatientProfileModel> createPatient({
    required String email,
    required String fullName,
    String? phone,
    String? password,
    String? dateOfBirth,
    String? sex,
    String? bloodGroup,
    String? address,
    String? villageLocality,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? baselineHealthInfo,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/api/v1/admin/users/patients',
      data: {
        'email': email.trim(),
        'full_name': fullName.trim(),
        'phone': phone?.trim(),
        if (password != null && password.isNotEmpty) 'password': password,
        'date_of_birth': dateOfBirth,
        'sex': sex ?? 'FEMALE',
        'blood_group': bloodGroup?.trim(),
        'address': address?.trim(),
        'village_locality': villageLocality?.trim(),
        'emergency_contact_name': emergencyContactName?.trim(),
        'emergency_contact_phone': emergencyContactPhone?.trim(),
        'baseline_health_info': baselineHealthInfo?.trim(),
      },
    );

    if (response.data != null) {
      try {
        final data = response.data!;
        return PatientProfileModel(
          id: data['patient_id'] as String? ?? '',
          userId: data['user_id'] as String? ?? '',
          fullName: data['full_name'] as String? ?? fullName,
          email: data['email'] as String? ?? email,
          phone: data['phone'] as String? ?? phone,
          villageLocality: data['village_locality'] as String? ?? villageLocality,
          bloodGroup: data['blood_group'] as String? ?? bloodGroup,
          healthRecord: data['health_record_number'] != null
              ? HealthRecordModel(
                  id: '',
                  recordNumber: data['health_record_number'] as String,
                  createdAt: data['created_at'] as String? ?? '',
                )
              : null,
          createdAt: data['created_at'] as String? ?? '',
          updatedAt: data['created_at'] as String? ?? '',
        );
      } catch (e) {
        throw ParsingFailure('Failed to parse patient creation response: $e');
      }
    } else {
      throw const ParsingFailure('Empty response from /api/v1/admin/users/patients');
    }
  }

  @override
  Future<List<PatientProfileModel>> listPatients() async {
    final response = await apiClient.get<List<dynamic>>(
      '/api/v1/admin/patients',
    );

    if (response.data != null) {
      try {
        return (response.data!)
            .map((item) => PatientProfileModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        throw ParsingFailure('Failed to parse admin patients list: $e');
      }
    } else {
      throw const ParsingFailure('Empty response from /api/v1/admin/patients');
    }
  }

  @override
  Future<bool> deleteUser({required String userId}) async {
    final response = await apiClient.delete(
      '/api/v1/admin/users/$userId',
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }
}

