import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/core/errors/failures.dart';
import 'package:pitpulse_mobile/core/network/api_client.dart';
import 'package:pitpulse_mobile/features/health_check/data/datasources/health_remote_data_source.dart';
import 'package:pitpulse_mobile/features/health_check/data/models/health_response_model.dart';
import 'package:pitpulse_mobile/features/health_check/presentation/screens/health_check_screen.dart';

class TestHealthRemoteDataSource implements HealthRemoteDataSource {
  final Future<HealthResponseModel> Function() onCheckHealth;
  @override
  final ApiClient apiClient;

  TestHealthRemoteDataSource({required this.onCheckHealth, required this.apiClient});

  @override
  Future<HealthResponseModel> checkHealth() => onCheckHealth();
}

void main() {
  testWidgets('HealthCheckScreen starts in loading state and never shows Connected by default', (tester) async {
    final completer = Completer<HealthResponseModel>();
    final testClient = ApiClient(baseUrl: 'http://127.0.0.1:8000');
    final dataSource = TestHealthRemoteDataSource(
      apiClient: testClient,
      onCheckHealth: () => completer.future,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HealthCheckScreen(dataSource: dataSource),
      ),
    );

    // Verify initial loading state
    expect(find.text('Connecting to PitPulse backend...'), findsWidgets);
    expect(find.text('Connected'), findsNothing);

    // Complete with success
    completer.complete(
      const HealthResponseModel(
        status: 'ok',
        service: 'pitpulse-api',
        version: '0.1.0',
        environment: 'development',
        timestamp: '2026-10-04T08:00:00Z',
      ),
    );

    await tester.pumpAndSettle();

    // Now verify connected state
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('pitpulse-api'), findsOneWidget);
    expect(find.text('0.1.0'), findsOneWidget);
  });

  testWidgets('HealthCheckScreen displays error state when communication fails', (tester) async {
    final testClient = ApiClient(baseUrl: 'http://127.0.0.1:8000');
    final dataSource = TestHealthRemoteDataSource(
      apiClient: testClient,
      onCheckHealth: () => Future.error(
        const NetworkFailure('Cannot connect to backend at http://127.0.0.1:8000. Ensure server is running.'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HealthCheckScreen(dataSource: dataSource),
      ),
    );

    await tester.pumpAndSettle();

    // Verify error state
    expect(find.text('Unable to connect'), findsOneWidget);
    expect(find.text('Connected'), findsNothing);
    expect(find.text('Test Connection Again'), findsOneWidget);
  });
}
