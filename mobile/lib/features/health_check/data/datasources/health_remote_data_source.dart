import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/health_response_model.dart';

abstract class HealthRemoteDataSource {
  Future<HealthResponseModel> checkHealth();
  ApiClient get apiClient;
}

class HealthRemoteDataSourceImpl implements HealthRemoteDataSource {
  @override
  final ApiClient apiClient;

  HealthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<HealthResponseModel> checkHealth() async {
    final response = await apiClient.get<Map<String, dynamic>>('/health');

    if (response.data != null) {
      try {
        return HealthResponseModel.fromJson(response.data!);
      } catch (e) {
        throw ParsingFailure('Failed to decode health response payload: $e');
      }
    } else {
      throw const ParsingFailure('Received empty body from health endpoint.');
    }
  }
}
