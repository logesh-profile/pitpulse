import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/core/network/api_client.dart';
import 'package:pitpulse_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pitpulse_mobile/features/pregnancy/data/datasources/pregnancy_remote_data_source.dart';

void main() {
  group('STAGE 4 LIVE INTEGRATION TEST: Pregnancy Foundation against real FastAPI + PostgreSQL', () {
    late ApiClient apiClient;
    late AuthRemoteDataSource authDataSource;
    late PregnancyRemoteDataSource pregnancyDataSource;

    setUp(() {
      apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000');
      authDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
      pregnancyDataSource = PregnancyRemoteDataSource(apiClient: apiClient);
    });

    test('Full Pregnancy Lifecycle: Register -> Add Pregnancy -> Calculate EDD/GA/Trimester -> List -> Update', () async {
      final rand = Random().nextInt(999999);
      final email = 'maternal_test_$rand@pitpulse.org';
      const password = 'Password123!';
      const fullName = 'Maternal Test Patient';

      // 1. Register new Patient
      final user = await authDataSource.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      expect(user.email, email);

      // 2. Login to get JWT access token
      final tokens = await authDataSource.login(email: email, password: password);
      expect(tokens.accessToken.isNotEmpty, isTrue);

      // Set token on ApiClient
      apiClient.setAuthToken(tokens.accessToken);

      // 3. Initial pregnancy list should be empty
      final initialList = await pregnancyDataSource.getMyPregnancies();
      expect(initialList.isEmpty, isTrue);

      // 4. Create pregnancy with LMP 56 days ago (8 weeks 0 days)
      final lmp = DateTime.now().subtract(const Duration(days: 56));
      final created = await pregnancyDataSource.createPregnancy(
        lmp: lmp,
        notes: 'Live integration test pregnancy record',
      );

      expect(created.pregnancyNumber, 1);
      expect(created.status, 'ACTIVE');
      expect(created.isActive, isTrue);
      expect(created.gestationalAgeWeeks, 8);
      expect(created.gestationalAgeDays, 0);
      expect(created.trimester, 1);
      expect(created.trimesterDisplay, '1st Trimester');
      expect(created.notes, 'Live integration test pregnancy record');

      // Verify EDD = LMP + 280 days
      final expectedEdd = lmp.add(const Duration(days: 280));
      expect(created.edd.year, expectedEdd.year);
      expect(created.edd.month, expectedEdd.month);
      expect(created.edd.day, expectedEdd.day);

      // 5. Query single pregnancy by ID
      final single = await pregnancyDataSource.getMyPregnancyById(created.id);
      expect(single.id, created.id);
      expect(single.pregnancyNumber, 1);

      // 6. Query all pregnancies -> contains 1
      final listAfter = await pregnancyDataSource.getMyPregnancies();
      expect(listAfter.length, 1);
      expect(listAfter.first.id, created.id);

      // 7. Update status to COMPLETED
      final updated = await pregnancyDataSource.updateMyPregnancy(
        pregnancyId: created.id,
        status: 'COMPLETED',
        notes: 'Delivery completed safely.',
      );
      expect(updated.status, 'COMPLETED');
      expect(updated.isActive, isFalse);

      // 8. Create Pregnancy #2
      final lmp2 = DateTime.now().subtract(const Duration(days: 21));
      final created2 = await pregnancyDataSource.createPregnancy(
        lmp: lmp2,
      );
      expect(created2.pregnancyNumber, 2);
      expect(created2.status, 'ACTIVE');

      // 9. List now has 2 pregnancies
      final finalList = await pregnancyDataSource.getMyPregnancies();
      expect(finalList.length, 2);
    });
  });
}
