enum UserRole {
  user('user', 'Pengunjung'),
  kasir('kasir', 'Kasir'),
  admin('admin', 'Admin');

  const UserRole(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static UserRole fromDb(String? value) {
    switch (value?.toLowerCase()) {
      case 'kasir':
        return UserRole.kasir;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }
}

class UserProfile {
  final String id;
  final String fullName;
  final UserRole role;
  final String? email;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.email,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, {String? email}) {
    return UserProfile(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? 'Pengguna',
      role: UserRole.fromDb(json['role'] as String?),
      email: email ?? json['email'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  UserProfile copyWith({String? fullName}) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      role: role,
      email: email,
      createdAt: createdAt,
    );
  }
}
