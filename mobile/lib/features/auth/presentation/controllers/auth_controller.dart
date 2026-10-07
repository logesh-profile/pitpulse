import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  String? get lastVerificationCode => authRemoteDataSource.lastVerificationCode;
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
      await secureStorageService.clearTokens();
      apiClient.setAuthToken(null);
      _currentUser = null;
      _accessToken = null;
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// Registers a patient with real Gmail ID, triggers 6-digit OTP code dispatch.
  Future<UserModel?> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await authRemoteDataSource.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return user;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e is Failure ? e.message : e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Verifies 6-digit OTP code sent to Gmail, activates patient account and logs in.
  Future<bool> verifyCode({
    required String email,
    required String code,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final tokenData = await authRemoteDataSource.verifyCode(
        email: email,
        code: code,
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

  /// Resends fresh 6-digit OTP code to Gmail.
  Future<bool> resendCode({required String email}) async {
    try {
      await authRemoteDataSource.resendCode(email: email);
      return true;
    } catch (e) {
      _errorMessage = e is Failure ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Performs real user login against backend and saves JWT tokens.
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

  /// Performs direct Google Sign-In with device account picker and JWT session issuance.
  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: '744072302437-ju26ffv5jmfp2j6q09j539b0knleslik.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        // User dismissed the Google account picker
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final auth = await account.authentication;
      final tokenData = await authRemoteDataSource.googleLogin(
        email: account.email,
        fullName: account.displayName,
        idToken: auth.idToken,
        googleId: account.id,
        photoUrl: account.photoUrl,
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
      if (e is Failure) {
        _errorMessage = e.message;
      } else {
        final errText = e.toString();
        if (errText.contains('10:') || errText.contains('sign_in_failed')) {
          _errorMessage =
              'Google Sign-In configuration needed: The SHA-1 certificate must be registered in Google Cloud Console. Please use your Gmail and password below to sign in or register.';
        } else {
          _errorMessage = 'Google Sign-In: $errText';
        }
      }
      notifyListeners();
      return false;
    }
  }

  /// Doctor / ASHA first-time login: saves personal details and updates profile status.
  Future<bool> completeProfile(Map<String, dynamic> profileData) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await authRemoteDataSource.completeProfile(profileData: profileData);
      _currentUser = updatedUser;
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

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final savedRefreshToken = await secureStorageService.getRefreshToken();
      if (savedRefreshToken != null && savedRefreshToken.isNotEmpty) {
        await authRemoteDataSource.logout(refreshToken: savedRefreshToken);
      }
    } catch (_) {
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
