class HealthRecordModel {
  final String id;
  final String recordNumber;
  final String createdAt;

  const HealthRecordModel({
    required this.id,
    required this.recordNumber,
    required this.createdAt,
  });

  factory HealthRecordModel.fromJson(Map<String, dynamic> json) {
    return HealthRecordModel(
      id: json['id'] as String? ?? '',
      recordNumber: json['record_number'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_number': recordNumber,
      'created_at': createdAt,
    };
  }
}

class PatientProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? dateOfBirth;
  final String? sex;
  final String? address;
  final String? villageLocality;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? bloodGroup;
  final String? baselineHealthInfo;
  final HealthRecordModel? healthRecord;
  final String createdAt;
  final String updatedAt;

  const PatientProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.sex,
    this.address,
    this.villageLocality,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.bloodGroup,
    this.baselineHealthInfo,
    this.healthRecord,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    return PatientProfileModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      sex: json['sex'] as String?,
      address: json['address'] as String?,
      villageLocality: json['village_locality'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      bloodGroup: json['blood_group'] as String?,
      baselineHealthInfo: json['baseline_health_info'] as String?,
      healthRecord: json['health_record'] != null
          ? HealthRecordModel.fromJson(json['health_record'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'date_of_birth': dateOfBirth,
      'sex': sex,
      'address': address,
      'village_locality': villageLocality,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'blood_group': bloodGroup,
      'baseline_health_info': baselineHealthInfo,
      'health_record': healthRecord?.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
