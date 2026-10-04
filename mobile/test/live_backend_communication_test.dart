import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/core/network/api_client.dart';
import 'package:pitpulse_mobile/features/health_check/data/datasources/health_remote_data_source.dart';

void main() {
  test('LIVE HTTP COMMUNICATION: Flutter ApiClient talks to live FastAPI backend', () async {
    final client = ApiClient(baseUrl: 'http://127.0.0.1:8000');
    final dataSource = HealthRemoteDataSourceImpl(apiClient: client);

    final health = await dataSource.checkHealth();

    expect(health.status, equals('ok'));
    expect(health.service, equals('pitpulse-api'));
    expect(health.version, equals('0.1.0'));
    expect(health.environment, equals('development'));
    expect(health.timestamp, isNotEmpty);
  });
}
