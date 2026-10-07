/// User domain model representing real PostgreSQL user metadata.
class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String fullName;
  final String role;
  final bool isActive;
  final bool isVerified;
  final bool isProfileCompleted;
  final int? age;
  final String? gender;
  final bool mustChangePassword;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.isVerified = false,
    this.isProfileCompleted = true,
    this.age,
    this.gender,
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
      isVerified: json['is_verified'] as bool? ?? false,
      isProfileCompleted: json['is_profile_completed'] as bool? ?? true,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
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
      'is_verified': isVerified,
      'is_profile_completed': isProfileCompleted,
      'age': age,
      'gender': gender,
      'must_change_password': mustChangePassword,
      'created_at': createdAt,
    };
  }
}
