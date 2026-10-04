import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthController extends ChangeNotifier {
  final AuthRemoteDataSource authRemoteDataSource;
  final SecureStorageService secureStorageService;
  final ApiClient apiClient;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _accessToken;
  String? _errorMessage;

  AuthController({
    required this.authRemoteDataSource,
    required this.secureStorageService,
    required this.apiClient,
  });

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;

  /// Checks whether an existing secure session exists on app startup and validates with backend.
  Future<void> checkAuthSession() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final savedRefreshToken = await secureStorageService.getRefreshToken();

      if (savedRefreshToken == null || savedRefreshToken.isEmpty) {
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
        _accessToken = null;
        apiClient.setAuthToken(null);
        notifyListeners();
        return;
      }

      // Refresh session against real PostgreSQL database
      final tokenData = await authRemoteDataSource.refreshToken(
        refreshToken: savedRefreshToken,
      );

      await secureStorageService.saveAccessToken(tokenData.accessToken);
      await secureStorageService.saveRefreshToken(tokenData.refreshToken);

      _accessToken = tokenData.accessToken;
      _currentUser = tokenData.user;
      apiClient.setAuthToken(tokenData.accessToken);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
    } catch (e) {
      // Clear invalid credentials
      await secureStorageService.clearTokens();
      apiClient.setAuthToken(null);
      _currentUser = null;
      _accessToken = null;
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// Performs real user login against PostgreSQL and saves JWT tokens in Android Keystore.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final tokenData = await authRemoteDataSource.login(
        email: email,
        password: password,
      );

      await secureStorageService.saveAccessToken(tokenData.accessToken);
      await secureStorageService.saveRefreshToken(tokenData.refreshToken);

      _accessToken = tokenData.accessToken;
      _currentUser = tokenData.user;
      apiClient.setAuthToken(tokenData.accessToken);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e is Failure ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Performs real user registration in PostgreSQL and automatically signs in.
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRemoteDataSource.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      // Auto-login after successful registration
      return await login(email: email, password: password);
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e is Failure ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Changes current password and completes activation for professional accounts.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final tokenData = await authRemoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      await secureStorageService.saveAccessToken(tokenData.accessToken);
      await secureStorageService.saveRefreshToken(tokenData.refreshToken);

      _accessToken = tokenData.accessToken;
      _currentUser = tokenData.user;
      apiClient.setAuthToken(tokenData.accessToken);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e is Failure ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Real logout: revokes refresh session on backend and clears local secure storage.
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final savedRefreshToken = await secureStorageService.getRefreshToken();
      if (savedRefreshToken != null && savedRefreshToken.isNotEmpty) {
        await authRemoteDataSource.logout(refreshToken: savedRefreshToken);
      }
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await secureStorageService.clearTokens();
      apiClient.setAuthToken(null);
      _currentUser = null;
      _accessToken = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    }
  }
}
