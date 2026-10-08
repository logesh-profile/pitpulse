import 'package:flutter_test/flutter_test.dart';
import 'package:pitpulse_mobile/features/patients/data/datasources/offline_facilities_dataset.dart';
import 'package:pitpulse_mobile/features/patients/data/models/healthcare_facility.dart';
import 'package:pitpulse_mobile/features/patients/services/offline_hospital_locator_service.dart';

void main() {
  group('Offline Hospital & Medical Radar Tests', () {
    final locatorService = OfflineHospitalLocatorService();

    test('Dataset contains diverse facilities including PHCs, GHs, Clinics, and Medical Shops', () {
      final facilities = OfflineFacilitiesDataset.facilities;
      expect(facilities.isNotEmpty, true);

      final hasPhc = facilities.any((f) => f.type == FacilityType.govtPhc);
      final hasGh = facilities.any((f) => f.type == FacilityType.govtHospital);
      final hasClinic = facilities.any((f) => f.type == FacilityType.privateClinic);
      final hasMedicalShop = facilities.any((f) => f.type == FacilityType.medicalShop);
      final hasFru = facilities.any((f) => f.type == FacilityType.fru24x7);

      expect(hasPhc, true);
      expect(hasGh, true);
      expect(hasClinic, true);
      expect(hasMedicalShop, true);
      expect(hasFru, true);
    });

    test('Haversine distance calculation produces accurate kilometer distance', () {
      // Distance between Anaimalai PHC (10.5843, 76.9312) and Pollachi GH (10.6588, 77.0094) ~11.8 km
      final dist = OfflineHospitalLocatorService.calculateDistanceKm(
        10.5843,
        76.9312,
        10.6588,
        77.0094,
      );
      expect(dist, greaterThan(11.0));
      expect(dist, lessThan(13.0));
    });

    test('Nearby facilities are sorted ascending by proximity', () {
      final sorted = locatorService.getNearbyFacilities(
        currentLat: 10.5843,
        currentLon: 76.9312,
      );

      expect(sorted.length, greaterThanOrEqualTo(5));
      for (int i = 0; i < sorted.length - 1; i++) {
        expect(sorted[i].distanceKm <= sorted[i + 1].distanceKm, true);
      }
    });

    test('Category filtering correctly filters medical shops', () {
      final pharmacies = locatorService.getNearbyFacilities(
        categoryFilter: 'pharmacy',
      );

      expect(pharmacies.isNotEmpty, true);
      for (final item in pharmacies) {
        expect(item.facility.type, FacilityType.medicalShop);
      }
    });

    test('Category filtering correctly filters 24x7 delivery units', () {
      final deliveryUnits = locatorService.getNearbyFacilities(
        categoryFilter: 'delivery',
      );

      expect(deliveryUnits.isNotEmpty, true);
      for (final item in deliveryUnits) {
        expect(item.facility.isDeliveryAvailable, true);
      }
    });

    test('Search query matches facility name or address', () {
      final results = locatorService.getNearbyFacilities(
        searchQuery: 'Pollachi',
      );

      expect(results.isNotEmpty, true);
      for (final item in results) {
        final matches = item.facility.name.contains('Pollachi') ||
            item.facility.address.contains('Pollachi');
        expect(matches, true);
      }
    });
  });
}
