import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/patient_profile_model.dart';

abstract class PatientRemoteDataSource {
  Future<PatientProfileModel> getMyProfile();

  Future<PatientProfileModel> updateMyProfile({
    String? dateOfBirth,
    String? sex,
    String? address,
    String? villageLocality,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    String? baselineHealthInfo,
  });
}

class PatientRemoteDataSourceImpl implements PatientRemoteDataSource {
  final ApiClient apiClient;

  PatientRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PatientProfileModel> getMyProfile() async {
    final response = await apiClient.get<Map<String, dynamic>>('/api/v1/patients/me');
    if (response.data != null) {
      try {
        return PatientProfileModel.fromJson(response.data!);
      } catch (e) {
        throw ParsingFailure('Failed to parse patient profile: $e');
      }
    } else {
      throw const ParsingFailure('Empty response from /api/v1/patients/me');
    }
  }

  @override
  Future<PatientProfileModel> updateMyProfile({
    String? dateOfBirth,
    String? sex,
    String? address,
    String? villageLocality,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    String? baselineHealthInfo,
  }) async {
    final payload = <String, dynamic>{};
    if (dateOfBirth != null && dateOfBirth.isNotEmpty) payload['date_of_birth'] = dateOfBirth;
    if (sex != null && sex.isNotEmpty) payload['sex'] = sex;
    if (address != null && address.isNotEmpty) payload['address'] = address;
    if (villageLocality != null && villageLocality.isNotEmpty) payload['village_locality'] = villageLocality;
    if (emergencyContactName != null && emergencyContactName.isNotEmpty) {
      payload['emergency_contact_name'] = emergencyContactName;
    }
    if (emergencyContactPhone != null && emergencyContactPhone.isNotEmpty) {
      payload['emergency_contact_phone'] = emergencyContactPhone;
    }
    if (bloodGroup != null && bloodGroup.isNotEmpty) payload['blood_group'] = bloodGroup;
    if (baselineHealthInfo != null && baselineHealthInfo.isNotEmpty) {
      payload['baseline_health_info'] = baselineHealthInfo;
    }

    final response = await apiClient.put<Map<String, dynamic>>(
      '/api/v1/patients/me',
      data: payload,
    );

    if (response.data != null) {
      try {
        return PatientProfileModel.fromJson(response.data!);
      } catch (e) {
        throw ParsingFailure('Failed to parse updated profile: $e');
      }
    } else {
      throw const ParsingFailure('Empty response from /api/v1/patients/me update');
    }
  }
}
