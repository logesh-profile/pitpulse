/// Model representing the backend /health JSON response.
class HealthResponseModel {
  final String status;
  final String service;
  final String version;
  final String environment;
  final String timestamp;

  const HealthResponseModel({
    required this.status,
    required this.service,
    required this.version,
    required this.environment,
    required this.timestamp,
  });

  factory HealthResponseModel.fromJson(Map<String, dynamic> json) {
    return HealthResponseModel(
      status: json['status'] as String? ?? 'unknown',
      service: json['service'] as String? ?? 'unknown',
      version: json['version'] as String? ?? '0.0.0',
      environment: json['environment'] as String? ?? 'unknown',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'service': service,
      'version': version,
      'environment': environment,
      'timestamp': timestamp,
    };
  }
}
