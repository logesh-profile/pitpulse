import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/token_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });

  Future<TokenModel> verifyCode({
    required String email,
    required String code,
  });

  Future<void> resendCode({
    required String email,
  });

  Future<TokenModel> login({
    required String email,
    required String password,
  });

  Future<TokenModel> refreshToken({
    required String refreshToken,
  });

  Future<void> logout({
    required String refreshToken,
  });

  Future<TokenModel> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<UserModel> completeProfile({
    required Map<String, dynamic> profileData,
  });

  Future<UserModel> getMe({
    required String accessToken,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/register',
      data: {
        'email': email.trim(),
        'password': password,
        'full_name': fullName.trim(),
        'phone': phone?.trim(),
      },
    );

    if (response.data != null) {
      try {
        final userJson = response.data!['user'] as Map<String, dynamic>? ?? response.data!;
        return UserModel.fromJson(userJson);
      } catch (e) {
        throw ParsingFailure('Failed to parse registration response: $e');
      }
    } else {
      throw const ParsingFailure('Empty response body from registration endpoint.');
    }
  }

  @override
  Future<TokenModel> verifyCode({
    required String email,
    required String code,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/verify-code',
      data: {
        'email': email.trim(),
        'code': code.trim(),
      },
    );

    if (response.data != null) {
      try {
        return TokenModel.fromJson(response.data!);
      } catch (e) {
        throw ParsingFailure('Failed to parse verification response: $e');
      }
    } else {
      throw const ParsingFailure('Empty response body from /auth/verify-code endpoint.');
    }
  }

  @override
  Future<void> resendCode({
    required String email,
  }) async {
    await apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/resend-code',
      data: {
        'email': email.trim(),
      },
    );
  }

  @override
  Future<TokenModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    if (response.data != null) {
      try {
        return TokenModel.fromJson(response.data!);
      } catch (e) {
        throw ParsingFailure('Failed to parse login response: $e');
      }
    } else {
      throw const ParsingFailure('Empty response body from login endpoint.');
    }
  }

  @override
  Future<TokenModel> refreshToken({
    required String refreshToken,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/refresh',
      data: {
        'refresh_token': refreshToken,
      },
    );

    if (response.data != null) {
      try {
        return TokenModel.fromJson(response.data!);
      } catch (e) {
        throw ParsingFailure('Failed to parse refresh response: $e');
      }
    } else {
      throw const ParsingFailure('Empty response body from refresh endpoint.');
    }
  }

  @override
  Future<void> logout({
    required String refreshToken,
  }) async {
    await apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/logout',
      data: {
        'refresh_token': refreshToken,
      },
    );
  }

  @override
  Future<TokenModel> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/change-password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );

    if (response.data != null) {
      try {
        return TokenModel.fromJson(response.data!);
      } catch (e) {
        throw ParsingFailure('Failed to parse password change response: $e');
      }
    } else {
      throw const ParsingFailure('Empty response body from /auth/change-password endpoint.');
    }
  }

  @override
  Future<UserModel> completeProfile({
    required Map<String, dynamic> profileData,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/api/v1/auth/complete-profile',
      data: profileData,
    );

    if (response.data != null) {
      try {
        return UserModel.fromJson(response.data!);
      } catch (e) {
        throw ParsingFailure('Failed to parse profile completion response: $e');
      }
    } else {
      throw const ParsingFailure('Empty response body from /auth/complete-profile endpoint.');
    }
  }

  @override
  Future<UserModel> getMe({
    required String accessToken,
  }) async {
    apiClient.setAuthToken(accessToken);
    final response = await apiClient.get<Map<String, dynamic>>(
      '/api/v1/auth/me',
    );

    if (response.data != null) {
      try {
        return UserModel.fromJson(response.data!);
      } catch (e) {
        throw ParsingFailure('Failed to parse profile response: $e');
      }
    } else {
      throw const ParsingFailure('Empty response body from /auth/me endpoint.');
    }
  }
}
