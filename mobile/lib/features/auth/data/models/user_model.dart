/// User domain model representing real PostgreSQL user metadata.
class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String fullName;
  final String role;
  final bool isActive;
  final bool mustChangePassword;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.mustChangePassword = false,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'PATIENT',
      isActive: json['is_active'] as bool? ?? true,
      mustChangePassword: json['must_change_password'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'must_change_password': mustChangePassword,
      'created_at': createdAt,
    };
  }
}
