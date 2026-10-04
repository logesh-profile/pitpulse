import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/core/network/api_client.dart';
import 'package:pitpulse_mobile/features/auth/data/datasources/auth_remote_data_source.dart';

void main() {
  test('LIVE INTEGRATION TEST: Full Auth Lifecycle against real FastAPI + PostgreSQL', () async {
    final client = ApiClient(baseUrl: 'http://127.0.0.1:8000');
    final authDataSource = AuthRemoteDataSourceImpl(apiClient: client);

    final uniqueSuffix = Random().nextInt(1000000).toString();
    final testEmail = 'mobile_user_$uniqueSuffix@pitpulse.org';
    const testPassword = 'RealSecurePassword123!';
    const testName = 'Mobile Real User';

    // 1. Real Registration
    final registeredUser = await authDataSource.register(
      email: testEmail,
      password: testPassword,
      fullName: testName,
      role: 'PATIENT',
    );

    expect(registeredUser.email, testEmail);
    expect(registeredUser.fullName, testName);
    expect(registeredUser.role, 'PATIENT');
    expect(registeredUser.id, isNotEmpty);

    // 2. Real Login
    final tokenData = await authDataSource.login(
      email: testEmail,
      password: testPassword,
    );

    expect(tokenData.accessToken, isNotEmpty);
    expect(tokenData.refreshToken, isNotEmpty);
    expect(tokenData.tokenType, 'bearer');
    expect(tokenData.user.email, testEmail);

    // 3. Real Authenticated /auth/me
    final profile = await authDataSource.getMe(accessToken: tokenData.accessToken);
    expect(profile.id, registeredUser.id);
    expect(profile.email, testEmail);
    expect(profile.role, 'PATIENT');

    // 4. Real Refresh Token Rotation
    final refreshedToken = await authDataSource.refreshToken(
      refreshToken: tokenData.refreshToken,
    );
    expect(refreshedToken.accessToken, isNotEmpty);
    expect(refreshedToken.refreshToken, isNot(equals(tokenData.refreshToken)));

    // 5. Real Logout
    await authDataSource.logout(refreshToken: refreshedToken.refreshToken);
  });
}
