import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorageService {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();
  Future<void> saveUserData(String userJson);
  Future<String?> getUserData();
  Future<void> clearTokens();
}

class FlutterSecureStorageServiceImpl implements SecureStorageService {
  final FlutterSecureStorage _storage;

  FlutterSecureStorageServiceImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _keyAccessToken = 'pitpulse_access_token';
  static const String _keyRefreshToken = 'pitpulse_refresh_token';
  static const String _keyUserData = 'pitpulse_user_data';

  @override
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  @override
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  @override
  Future<void> saveUserData(String userJson) async {
    await _storage.write(key: _keyUserData, value: userJson);
  }

  @override
  Future<String?> getUserData() async {
    return await _storage.read(key: _keyUserData);
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserData);
  }
}
