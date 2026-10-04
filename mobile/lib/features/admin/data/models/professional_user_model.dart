class ProvisionedAccountResult {
  final String userId;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final String activationToken;
  final String temporaryPassword;
  final bool mustChangePassword;
  final String? detailsKey;
  final String? detailsValue;

  const ProvisionedAccountResult({
    required this.userId,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    required this.activationToken,
    required this.temporaryPassword,
    required this.mustChangePassword,
    this.detailsKey,
    this.detailsValue,
  });

  factory ProvisionedAccountResult.fromJson(Map<String, dynamic> json) {
    final token = json['activation_token'] as String? ?? json['temporary_password'] as String? ?? '';
    return ProvisionedAccountResult(
      userId: json['user_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? '',
      activationToken: token,
      temporaryPassword: json['temporary_password'] as String? ?? token,
      mustChangePassword: json['must_change_password'] as bool? ?? true,
      detailsKey: json.containsKey('medical_license_number') ? 'License' : (json.containsKey('worker_id_code') ? 'Worker Code' : null),
      detailsValue: json['medical_license_number'] as String? ?? json['worker_id_code'] as String?,
    );
  }
}

class ProfessionalUserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final bool isActive;
  final bool mustChangePassword;
  final String createdAt;
  final Map<String, dynamic>? details;

  const ProfessionalUserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    required this.isActive,
    required this.mustChangePassword,
    required this.createdAt,
    this.details,
  });

  factory ProfessionalUserModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalUserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      mustChangePassword: json['must_change_password'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
      details: json['details'] as Map<String, dynamic>?,
    );
  }
}
