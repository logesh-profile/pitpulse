class AshaAssignmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String? patientEmail;
  final String? patientPhone;
  final DateTime? dateOfBirth;
  final int? age;
  final String? bloodGroup;
  final String? emergencyContact;
  final String? healthRecordNumber;
  final String? villageLocality;
  final bool hasActivePregnancy;
  final String? pregnancyId;
  final int? pregnancyNumber;
  final int? gestationalAgeWeeks;
  final DateTime? activePregnancyEdd;
  final String riskLevel;
  final DateTime? lastVisitDate;
  final int totalVisits;
  final String ashaWorkerId;
  final String? ashaWorkerName;
  final String status;
  final DateTime assignedAt;
  final DateTime? unassignedAt;
  final String? notes;
  final List<String> requiredDuties;

  const AshaAssignmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientEmail,
    this.patientPhone,
    this.dateOfBirth,
    this.age,
    this.bloodGroup,
    this.emergencyContact,
    this.healthRecordNumber,
    this.villageLocality,
    this.hasActivePregnancy = false,
    this.pregnancyId,
    this.pregnancyNumber,
    this.gestationalAgeWeeks,
    this.activePregnancyEdd,
    this.riskLevel = 'NORMAL',
    this.lastVisitDate,
    this.totalVisits = 0,
    required this.ashaWorkerId,
    this.ashaWorkerName,
    required this.status,
    required this.assignedAt,
    this.unassignedAt,
    this.notes,
    this.requiredDuties = const [],
  });

  factory AshaAssignmentModel.fromJson(Map<String, dynamic> json) {
    final patientId = (json['patient_id'] ?? json['id']) as String;
    final patientName = (json['patient_name'] ?? json['full_name']) as String? ?? 'Patient';
    final patientEmail = (json['patient_email'] ?? json['email']) as String?;
    final patientPhone = (json['patient_phone'] ?? json['phone']) as String?;

    String? hrNum = json['health_record_number'] as String?;
    if (hrNum == null && json['health_record'] != null) {
      hrNum = json['health_record']['record_number'] as String?;
    }

    bool hasActivePreg = json['has_active_pregnancy'] as bool? ?? false;
    String? pregId = json['pregnancy_id'] as String?;
    int? pregNum = json['pregnancy_number'] as int?;
    if (json['active_pregnancy'] != null) {
      hasActivePreg = true;
      pregId = json['active_pregnancy']['id'] as String?;
      pregNum = json['active_pregnancy']['pregnancy_number'] as int?;
    }

    final rawDuties = json['required_duties'];
    List<String> duties = [];
    if (rawDuties is List) {
      duties = rawDuties.map((e) => e.toString()).toList();
    }

    return AshaAssignmentModel(
      id: json['id'] as String,
      patientId: patientId,
      patientName: patientName,
      patientEmail: patientEmail,
      patientPhone: patientPhone,
      dateOfBirth: json['date_of_birth'] != null ? DateTime.tryParse(json['date_of_birth'] as String) : null,
      age: json['age'] as int?,
      bloodGroup: json['blood_group'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      healthRecordNumber: hrNum,
      villageLocality: json['village_locality'] as String?,
      hasActivePregnancy: hasActivePreg,
      pregnancyId: pregId,
      pregnancyNumber: pregNum,
      gestationalAgeWeeks: json['gestational_age_weeks'] as int?,
      activePregnancyEdd: json['active_pregnancy_edd'] != null ? DateTime.tryParse(json['active_pregnancy_edd'] as String) : null,
      riskLevel: json['risk_level'] as String? ?? 'NORMAL',
      lastVisitDate: json['last_visit_date'] != null
          ? DateTime.tryParse(json['last_visit_date'] as String)
          : null,
      totalVisits: json['total_visits'] as int? ?? 0,
      ashaWorkerId: (json['asha_worker_id'] ?? '') as String,
      ashaWorkerName: json['asha_worker_name'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : (json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now()),
      unassignedAt: json['unassigned_at'] != null
          ? DateTime.tryParse(json['unassigned_at'] as String)
          : null,
      notes: json['notes'] as String?,
      requiredDuties: duties,
    );
  }
}


class HomeVisitModel {
  final String id;
  final String patientId;
  final String patientName;
  final String? patientHealthRecordNumber;
  final String? pregnancyId;
  final int? pregnancyNumber;
  final String ashaWorkerId;
  final String ashaWorkerName;
  final DateTime visitDate;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String status;
  final String purpose;
  final String? observations;
  final String? notes;
  final bool followUpRequired;
  final String? followUpNotes;
  final DateTime createdAt;

  const HomeVisitModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientHealthRecordNumber,
    this.pregnancyId,
    this.pregnancyNumber,
    required this.ashaWorkerId,
    required this.ashaWorkerName,
    required this.visitDate,
    this.startedAt,
    this.completedAt,
    required this.status,
    required this.purpose,
    this.observations,
    this.notes,
    this.followUpRequired = false,
    this.followUpNotes,
    required this.createdAt,
  });

  factory HomeVisitModel.fromJson(Map<String, dynamic> json) {
    return HomeVisitModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      patientName: json['patient_name'] as String? ?? 'Patient',
      patientHealthRecordNumber: json['patient_health_record_number'] as String?,
      pregnancyId: json['pregnancy_id'] as String?,
      pregnancyNumber: json['pregnancy_number'] as int?,
      ashaWorkerId: json['asha_worker_id'] as String,
      ashaWorkerName: json['asha_worker_name'] as String? ?? 'ASHA Worker',
      visitDate: DateTime.parse(json['visit_date'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      status: json['status'] as String? ?? 'COMPLETED',
      purpose: json['purpose'] as String? ?? 'Routine Checkup',
      observations: json['observations'] as String?,
      notes: json['notes'] as String?,
      followUpRequired: json['follow_up_required'] as bool? ?? false,
      followUpNotes: json['follow_up_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class MaternalVitalRecordModel {
  final String id;
  final String pregnancyId;
  final int? pregnancyNumber;
  final String? homeVisitId;
  final String recordedByUserId;
  final String recordedByName;
  final String recordedByRole;
  final DateTime recordedAt;
  final int? systolicBp;
  final int? diastolicBp;
  final double? weightKg;
  final double? temperatureC;
  final String? notes;
  final DateTime createdAt;

  const MaternalVitalRecordModel({
    required this.id,
    required this.pregnancyId,
    this.pregnancyNumber,
    this.homeVisitId,
    required this.recordedByUserId,
    required this.recordedByName,
    required this.recordedByRole,
    required this.recordedAt,
    this.systolicBp,
    this.diastolicBp,
    this.weightKg,
    this.temperatureC,
    this.notes,
    required this.createdAt,
  });

  factory MaternalVitalRecordModel.fromJson(Map<String, dynamic> json) {
    return MaternalVitalRecordModel(
      id: json['id'] as String,
      pregnancyId: json['pregnancy_id'] as String,
      pregnancyNumber: json['pregnancy_number'] as int?,
      homeVisitId: json['home_visit_id'] as String?,
      recordedByUserId: json['recorded_by_user_id'] as String,
      recordedByName: json['recorded_by_name'] as String? ?? 'Health Worker',
      recordedByRole: json['recorded_by_role'] as String? ?? 'ASHA',
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      systolicBp: json['systolic_bp'] as int?,
      diastolicBp: json['diastolic_bp'] as int?,
      weightKg: (json['weight_kg'] != null) ? (json['weight_kg'] as num).toDouble() : null,
      temperatureC: (json['temperature_c'] != null) ? (json['temperature_c'] as num).toDouble() : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  bool get hasBp => systolicBp != null && diastolicBp != null;

  String get bpDisplay {
    if (systolicBp != null && diastolicBp != null) {
      return '$systolicBp / $diastolicBp mmHg';
    } else if (systolicBp != null) {
      return '$systolicBp mmHg (Systolic)';
    } else if (diastolicBp != null) {
      return '$diastolicBp mmHg (Diastolic)';
    }
    return 'Not recorded';
  }

  String get weightDisplay {
    if (weightKg != null) {
      return '${weightKg!.toStringAsFixed(1)} kg';
    }
    return 'Not recorded';
  }

  String get temperatureDisplay {
    if (temperatureC != null) {
      return '${temperatureC!.toStringAsFixed(1)} °C';
    }
    return 'Not recorded';
  }
}
