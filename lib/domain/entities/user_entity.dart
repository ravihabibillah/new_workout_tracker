/// User entity - pure domain model
class UserEntity {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String preferredUnit; // 'kg' or 'lbs'
  final int defaultRestTime; // in seconds

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.preferredUnit = 'kg',
    this.defaultRestTime = 90,
  });

  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? preferredUnit,
    int? defaultRestTime,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      preferredUnit: preferredUnit ?? this.preferredUnit,
      defaultRestTime: defaultRestTime ?? this.defaultRestTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserEntity(id: $id, email: $email, displayName: $displayName)';
  }
}
