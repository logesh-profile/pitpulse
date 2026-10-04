import 'package:pitpulse_mobile/core/network/api_client.dart';
import 'package:pitpulse_mobile/features/asha/data/models/asha_models.dart';
import '../models/doctor_models.dart';

class DoctorRemoteDataSource {
  final ApiClient _apiClient;

  DoctorRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  Future<List<DoctorPatientModel>> getDoctorPatients() async {
    final response = await _apiClient.get('/api/v1/doctor/me/patients');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((json) => DoctorPatientModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<DoctorPatientModel>> getUnassignedPatients() async {
    final response = await _apiClient.get('/api/v1/doctor/me/patients/unassigned');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((json) => DoctorPatientModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<DoctorAshaModel>> getAvailableAshas() async {
    final response = await _apiClient.get('/api/v1/doctor/me/available-asha');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((json) => DoctorAshaModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<AshaAssignmentModel> assignAshaToPatient({
    required String patientId,
    required String ashaWorkerId,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'asha_worker_id': ashaWorkerId,
    };
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }

    final response = await _apiClient.post(
      '/api/v1/doctor/me/patients/$patientId/asha-assignment',
      data: body,
    );
    return AshaAssignmentModel.fromJson(response.data as Map<String, dynamic>);
  }
}
