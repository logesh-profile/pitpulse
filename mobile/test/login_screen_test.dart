import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/core/network/api_client.dart';
import 'package:pitpulse_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pitpulse_mobile/features/auth/presentation/screens/login_screen.dart';

import 'auth_controller_test.dart';

void main() {
  group('LoginScreen Widget Tests', () {
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

    testWidgets('Displays form fields, submit button, and navigation button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authController: controller),
        ),
      );

      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('nav_to_register_button')), findsOneWidget);
    });

    testWidgets('Shows validation errors when submitting empty form', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authController: controller),
        ),
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets('Displays error banner when authentication fails', (tester) async {
      fakeRemote.shouldFail = true;

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authController: controller),
        ),
      );

      await tester.enterText(find.byKey(const Key('login_email_field')), 'user@pitpulse.org');
      await tester.enterText(find.byKey(const Key('login_password_field')), 'WrongPassword123!');
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email or password.'), findsOneWidget);
    });
  });
}
