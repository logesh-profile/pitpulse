import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../data/datasources/offline_facilities_dataset.dart';
import '../data/models/healthcare_facility.dart';

class FacilityWithDistance {
  final HealthcareFacility facility;
  final double distanceKm;
  final String compassDirection;

  const FacilityWithDistance({
    required this.facility,
    required this.distanceKm,
    required this.compassDirection,
  });

  String get distanceDisplay {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}

class OfflineHospitalLocatorService {
  // Default regional anchor if GPS hardware is unavailable or disabled
  static const double fallbackLat = 10.5843;
  static const double fallbackLon = 76.9312;

  /// Haversine straight-line distance calculation in kilometers
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  /// Calculates compass bearing from origin to target
  static String calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double p = 0.017453292519943295;
    final double dLon = (lon2 - lon1) * p;
    final double y = sin(dLon) * cos(lat2 * p);
    final double x = cos(lat1 * p) * sin(lat2 * p) -
        sin(lat1 * p) * cos(lat2 * p) * cos(dLon);
    double brng = (atan2(y, x) * 180 / pi + 360) % 360;

    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final int index = ((brng + 22.5) % 360 / 45).floor();
    return directions[index % 8];
  }

  /// Attempts to read current device GPS position with graceful offline fallback
  Future<Position?> getCurrentPosition() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Retrieves and sorts all nearby facilities based on current or anchor coordinates
  List<FacilityWithDistance> getNearbyFacilities({
    double? currentLat,
    double? currentLon,
    String? categoryFilter,
    String? searchQuery,
  }) {
    final double originLat = currentLat ?? fallbackLat;
    final double originLon = currentLon ?? fallbackLon;

    final List<HealthcareFacility> all = OfflineFacilitiesDataset.facilities;

    final filtered = all.where((facility) {
      // Category filter check
      if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'all') {
        if (categoryFilter == 'govt') {
          if (facility.type != FacilityType.govtPhc &&
              facility.type != FacilityType.govtHospital &&
              facility.type != FacilityType.fru24x7) {
            return false;
          }
        } else if (categoryFilter == 'delivery') {
          if (!facility.isDeliveryAvailable) return false;
        } else if (categoryFilter == 'private') {
          if (facility.type != FacilityType.privateClinic) return false;
        } else if (categoryFilter == 'pharmacy') {
          if (!facility.isPharmacy) return false;
        }
      }

      // Search query check
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchesName = facility.name.toLowerCase().contains(query);
        final matchesAddress = facility.address.toLowerCase().contains(query);
        final matchesCategory = facility.categoryLabel.toLowerCase().contains(query);
        final matchesFeature = facility.features.any((f) => f.toLowerCase().contains(query));
        if (!matchesName && !matchesAddress && !matchesCategory && !matchesFeature) {
          return false;
        }
      }

      return true;
    }).toList();

    // Map to distance model and sort ascending
    final List<FacilityWithDistance> result = filtered.map((facility) {
      final double dist = calculateDistanceKm(
        originLat,
        originLon,
        facility.latitude,
        facility.longitude,
      );
      final String bearing = calculateBearing(
        originLat,
        originLon,
        facility.latitude,
        facility.longitude,
      );
      return FacilityWithDistance(
        facility: facility,
        distanceKm: dist,
        compassDirection: bearing,
      );
    }).toList();

    result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return result;
  }
}
