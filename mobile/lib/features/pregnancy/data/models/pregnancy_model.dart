class PregnancyModel {
  final String id;
  final String patientId;
  final int pregnancyNumber;
  final String status;
  final DateTime lmp;
  final DateTime edd;
  final int gestationalAgeWeeks;
  final int gestationalAgeDays;
  final String gestationalAgeDisplay;
  final int trimester;
  final String trimesterDisplay;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PregnancyModel({
    required this.id,
    required this.patientId,
    required this.pregnancyNumber,
    required this.status,
    required this.lmp,
    required this.edd,
    required this.gestationalAgeWeeks,
    required this.gestationalAgeDays,
    required this.gestationalAgeDisplay,
    required this.trimester,
    required this.trimesterDisplay,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory PregnancyModel.fromJson(Map<String, dynamic> json) {
    return PregnancyModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      pregnancyNumber: json['pregnancy_number'] as int,
      status: json['status'] as String,
      lmp: DateTime.parse(json['lmp'] as String),
      edd: DateTime.parse(json['edd'] as String),
      gestationalAgeWeeks: json['gestational_age_weeks'] as int? ?? 0,
      gestationalAgeDays: json['gestational_age_days'] as int? ?? 0,
      gestationalAgeDisplay: json['gestational_age_display'] as String? ?? '0 weeks 0 days',
      trimester: json['trimester'] as int? ?? 1,
      trimesterDisplay: json['trimester_display'] as String? ?? '1st Trimester',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'pregnancy_number': pregnancyNumber,
      'status': status,
      'lmp': lmp.toIso8601String().split('T').first,
      'edd': edd.toIso8601String().split('T').first,
      'gestational_age_weeks': gestationalAgeWeeks,
      'gestational_age_days': gestationalAgeDays,
      'gestational_age_display': gestationalAgeDisplay,
      'trimester': trimester,
      'trimester_display': trimesterDisplay,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
