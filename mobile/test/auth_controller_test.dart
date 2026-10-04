import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/core/errors/failures.dart';
import 'package:pitpulse_mobile/core/network/api_client.dart';
import 'package:pitpulse_mobile/core/storage/secure_storage_service.dart';
import 'package:pitpulse_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pitpulse_mobile/features/auth/data/models/token_model.dart';
import 'package:pitpulse_mobile/features/auth/data/models/user_model.dart';
import 'package:pitpulse_mobile/features/auth/presentation/controllers/auth_controller.dart';

class InMemorySecureStorageService implements SecureStorageService {
  String? _access;
  String? _refresh;

  @override
  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
  }

  @override
  Future<String?> getAccessToken() async => _access;

  @override
  Future<String?> getRefreshToken() async => _refresh;

  @override
  Future<void> saveAccessToken(String token) async => _access = token;

  @override
  Future<void> saveRefreshToken(String token) async => _refresh = token;
}

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  bool shouldFail = false;

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required String role,
  }) async {
    if (shouldFail) throw const ServerFailure('Registration failed.');
    return UserModel(
      id: 'mock-uuid',
      email: email,
      fullName: fullName,
      phone: phone,
      role: role,
      isActive: true,
      createdAt: '2026-10-04',
    );
  }

  @override
  Future<TokenModel> login({required String email, required String password}) async {
    if (shouldFail) throw const ServerFailure('Invalid email or password.');
    return TokenModel(
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
      tokenType: 'bearer',
      expiresIn: 1800,
      user: UserModel(
        id: 'mock-uuid',
        email: email,
        fullName: 'Test User',
        role: 'PATIENT',
        isActive: true,
        createdAt: '2026-10-04',
      ),
    );
  }

  @override
  Future<TokenModel> refreshToken({required String refreshToken}) async {
    if (shouldFail) throw const ServerFailure('Expired token');
    return TokenModel(
      accessToken: 'new-access-token',
      refreshToken: 'new-refresh-token',
      tokenType: 'bearer',
      expiresIn: 1800,
      user: const UserModel(
        id: 'mock-uuid',
        email: 'saved@pitpulse.org',
        fullName: 'Saved User',
        role: 'PATIENT',
        isActive: true,
        createdAt: '2026-10-04',
      ),
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {}

  @override
  Future<UserModel> getMe({required String accessToken}) async {
    return const UserModel(
      id: 'mock-uuid',
      email: 'saved@pitpulse.org',
      fullName: 'Saved User',
      role: 'PATIENT',
      isActive: true,
      createdAt: '2026-10-04',
    );
  }
}

void main() {
  group('AuthController State Machine', () {
    late InMemorySecureStorageService storage;
    late FakeAuthRemoteDataSource fakeRemote;
    late ApiClient apiClient;
    late AuthController controller;

    setUp(() {
      storage = InMemorySecureStorageService();
      fakeRemote = FakeAuthRemoteDataSource();
      apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000');
      controller = AuthController(
        authRemoteDataSource: fakeRemote,
        secureStorageService: storage,
        apiClient: apiClient,
      );
    });

    test('Initial state is AuthInitial', () {
      expect(controller.status, AuthStatus.initial);
      expect(controller.isAuthenticated, false);
    });

    test('Successful login transitions to Authenticated and persists tokens', () async {
      final success = await controller.login(email: 'test@pitpulse.org', password: 'Password123!');

      expect(success, true);
      expect(controller.status, AuthStatus.authenticated);
      expect(controller.isAuthenticated, true);
      expect(controller.currentUser?.email, 'test@pitpulse.org');
      expect(await storage.getAccessToken(), 'test-access-token');
      expect(await storage.getRefreshToken(), 'test-refresh-token');
    });

    test('Failed login transitions to AuthStatus.error', () async {
      fakeRemote.shouldFail = true;

      final success = await controller.login(email: 'test@pitpulse.org', password: 'WrongPassword!');

      expect(success, false);
      expect(controller.status, AuthStatus.error);
      expect(controller.isAuthenticated, false);
      expect(controller.errorMessage, 'Invalid email or password.');
    });

    test('Logout clears session, secure tokens, and resets to Unauthenticated', () async {
      await controller.login(email: 'test@pitpulse.org', password: 'Password123!');
      expect(controller.isAuthenticated, true);

      await controller.logout();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.isAuthenticated, false);
      expect(controller.currentUser, null);
      expect(await storage.getAccessToken(), null);
      expect(await storage.getRefreshToken(), null);
    });

    test('Startup session restoration restores authenticated state from refresh token', () async {
      await storage.saveRefreshToken('existing-valid-refresh-token');

      await controller.checkAuthSession();

      expect(controller.status, AuthStatus.authenticated);
      expect(controller.isAuthenticated, true);
      expect(controller.currentUser?.email, 'saved@pitpulse.org');
    });
  });
}
