import 'dart:io';
import 'package:flutter/foundation.dart';

/// Application configuration management for environment, networking, and platform differences.
class AppConfig {
  static const String appName = 'PitPulse';
  static const String appVersion = '0.1.0';

  // Can be overridden via --dart-define=BACKEND_URL=http://your-ip:8000
  static const String _customBackendUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');

  /// Resolves the default backend URL based on platform and execution context.
  static String get defaultBaseUrl {
    if (_customBackendUrl.isNotEmpty) {
      return _customBackendUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    if (Platform.isAndroid) {
      // Physical device Wi-Fi backend IP (fallback to emulator loopback if overridden)
      return 'http://10.63.229.152:8000';
    }

    // Windows, macOS, Linux desktop
    return 'http://127.0.0.1:8000';
  }

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;
}
