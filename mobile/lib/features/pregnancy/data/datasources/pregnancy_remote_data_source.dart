import 'package:pitpulse_mobile/core/network/api_client.dart';
import 'package:pitpulse_mobile/features/pregnancy/data/models/pregnancy_model.dart';

class PregnancyRemoteDataSource {
  final ApiClient _apiClient;

  PregnancyRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<PregnancyModel> createPregnancy({
    required DateTime lmp,
    int? pregnancyNumber,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'lmp': lmp.toIso8601String().split('T').first,
    };
    if (pregnancyNumber != null) {
      body['pregnancy_number'] = pregnancyNumber;
    }
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }

    final response = await _apiClient.post(
      '/api/v1/patients/me/pregnancies',
      data: body,
    );
    return PregnancyModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PregnancyModel>> getMyPregnancies() async {
    final response = await _apiClient.get('/api/v1/patients/me/pregnancies');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((json) => PregnancyModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<PregnancyModel> getMyPregnancyById(String pregnancyId) async {
    final response = await _apiClient.get('/api/v1/patients/me/pregnancies/$pregnancyId');
    return PregnancyModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PregnancyModel> updateMyPregnancy({
    required String pregnancyId,
    String? status,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status;
    if (notes != null) body['notes'] = notes;

    final response = await _apiClient.patch(
      '/api/v1/patients/me/pregnancies/$pregnancyId',
      data: body,
    );
    return PregnancyModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PregnancyModel>> getPatientPregnancies(String patientId) async {
    final response = await _apiClient.get('/api/v1/patients/$patientId/pregnancies');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((json) => PregnancyModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}
