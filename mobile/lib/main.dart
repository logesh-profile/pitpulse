import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Instantiate network client with platform-configured base URL
  final apiClient = ApiClient(baseUrl: AppConfig.defaultBaseUrl);

  runApp(PitPulseApp(apiClient: apiClient));
}
