import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/features/health_check/data/models/health_response_model.dart';

void main() {
  group('HealthResponseModel', () {
    test('correctly deserializes from valid backend /health JSON payload', () {
      final json = {
        'status': 'ok',
        'service': 'pitpulse-api',
        'version': '0.1.0',
        'environment': 'development',
        'timestamp': '2026-10-04T08:00:00.000Z',
      };

      final model = HealthResponseModel.fromJson(json);

      expect(model.status, 'ok');
      expect(model.service, 'pitpulse-api');
      expect(model.version, '0.1.0');
      expect(model.environment, 'development');
      expect(model.timestamp, '2026-10-04T08:00:00.000Z');
    });

    test('serializes back to JSON map matching backend contract', () {
      const model = HealthResponseModel(
        status: 'ok',
        service: 'pitpulse-api',
        version: '0.1.0',
        environment: 'development',
        timestamp: '2026-10-04T08:00:00.000Z',
      );

      final json = model.toJson();

      expect(json['status'], 'ok');
      expect(json['service'], 'pitpulse-api');
      expect(json['version'], '0.1.0');
      expect(json['environment'], 'development');
    });
  });
}
