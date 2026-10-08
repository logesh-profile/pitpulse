enum FacilityType {
  govtPhc,
  govtHospital,
  privateClinic,
  medicalShop,
  fru24x7,
}

class HealthcareFacility {
  final String id;
  final String name;
  final FacilityType type;
  final String categoryLabel;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final bool isOpen24x7;
  final List<String> features;
  final String operatingHours;

  const HealthcareFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.categoryLabel,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.isOpen24x7,
    required this.features,
    required this.operatingHours,
  });

  bool get isDeliveryAvailable =>
      type == FacilityType.fru24x7 ||
      features.any((f) => f.toLowerCase().contains('delivery'));

  bool get isPharmacy => type == FacilityType.medicalShop;
}
