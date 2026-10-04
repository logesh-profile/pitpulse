import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
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

  Future<List<ProfessionalUserModel>> listProfessionals();

  Future<bool> toggleUserStatus({
    required String userId,
    required bool isActive,
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
}
