class DoctorPatientModel {
  final String patientId;
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? villageLocality;
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final bool hasActivePregnancy;
  final int? activePregnancyGaWeeks;
  final DateTime? activePregnancyEdd;
  final String? assignedAshaName;
  final String? assignedAshaId;
  final DateTime createdAt;

  DoctorPatientModel({
    required this.patientId,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.villageLocality,
    this.dateOfBirth,
    this.bloodGroup,
    this.hasActivePregnancy = false,
    this.activePregnancyGaWeeks,
    this.activePregnancyEdd,
    this.assignedAshaName,
    this.assignedAshaId,
    required this.createdAt,
  });

  factory DoctorPatientModel.fromJson(Map<String, dynamic> json) {
    return DoctorPatientModel(
      patientId: json['patient_id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      villageLocality: json['village_locality'] as String?,
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth'] as String) : null,
      bloodGroup: json['blood_group'] as String?,
      hasActivePregnancy: json['has_active_pregnancy'] as bool? ?? false,
      activePregnancyGaWeeks: json['active_pregnancy_ga_weeks'] as int?,
      activePregnancyEdd: json['active_pregnancy_edd'] != null
          ? DateTime.parse(json['active_pregnancy_edd'] as String)
          : null,
      assignedAshaName: json['assigned_asha_name'] as String?,
      assignedAshaId: json['assigned_asha_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class DoctorAshaModel {
  final String ashaId;
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? workerIdCode;
  final String? assignedArea;
  final String? primaryHealthCenter;
  final int activePatientsCount;

  DoctorAshaModel({
    required this.ashaId,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.workerIdCode,
    this.assignedArea,
    this.primaryHealthCenter,
    this.activePatientsCount = 0,
  });

  factory DoctorAshaModel.fromJson(Map<String, dynamic> json) {
    return DoctorAshaModel(
      ashaId: json['asha_id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      workerIdCode: json['worker_id_code'] as String?,
      assignedArea: json['assigned_area'] as String?,
      primaryHealthCenter: json['primary_health_center'] as String?,
      activePatientsCount: json['active_patients_count'] as int? ?? 0,
    );
  }
}
