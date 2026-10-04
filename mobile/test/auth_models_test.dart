import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/features/auth/data/models/token_model.dart';
import 'package:pitpulse_mobile/features/auth/data/models/user_model.dart';

void main() {
  group('Auth Models Suite', () {
    test('UserModel deserializes and serializes accurately', () {
      final json = {
        'id': 'b158f534-f34a-4d7a-8b1a-2e3f4a5b6c7d',
        'email': 'doctor.sharma@pitpulse.org',
        'phone': '+919876543210',
        'full_name': 'Dr. Sharma',
        'role': 'DOCTOR',
        'is_active': true,
        'created_at': '2026-10-04T09:00:00Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'b158f534-f34a-4d7a-8b1a-2e3f4a5b6c7d');
      expect(user.email, 'doctor.sharma@pitpulse.org');
      expect(user.phone, '+919876543210');
      expect(user.fullName, 'Dr. Sharma');
      expect(user.role, 'DOCTOR');
      expect(user.isActive, true);

      final outJson = user.toJson();
      expect(outJson['email'], 'doctor.sharma@pitpulse.org');
    });

    test('TokenModel deserializes tokens and nested user object', () {
      final json = {
        'access_token': 'jwt.access.token',
        'refresh_token': 'secure_refresh_token_123',
        'token_type': 'bearer',
        'expires_in': 1800,
        'user': {
          'id': '11111111-2222-3333-4444-555555555555',
          'email': 'patient@pitpulse.org',
          'full_name': 'Patient Name',
          'role': 'PATIENT',
          'is_active': true,
          'created_at': '2026-10-04T09:00:00Z',
        },
      };

      final token = TokenModel.fromJson(json);

      expect(token.accessToken, 'jwt.access.token');
      expect(token.refreshToken, 'secure_refresh_token_123');
      expect(token.tokenType, 'bearer');
      expect(token.user.email, 'patient@pitpulse.org');
    });
  });
}
