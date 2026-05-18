import '../../domain/entities/user_entity.dart';

/// User model with JSON serialization
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.preferredUnit,
    super.defaultRestTime,
  });

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      preferredUnit: entity.preferredUnit,
      defaultRestTime: entity.defaultRestTime,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      preferredUnit: json['preferredUnit'] as String? ?? 'kg',
      defaultRestTime: json['defaultRestTime'] as int? ?? 90,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'preferredUnit': preferredUnit,
      'defaultRestTime': defaultRestTime,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      preferredUnit: preferredUnit,
      defaultRestTime: defaultRestTime,
    );
  }
}
