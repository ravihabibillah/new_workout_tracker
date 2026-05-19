import '../../domain/entities/exercise_library_entity.dart';

/// Exercise library model with JSON serialization
class ExerciseLibraryModel extends ExerciseLibraryEntity {
  const ExerciseLibraryModel({
    required super.id,
    super.userId,
    required super.name,
    required super.muscleGroup,
    super.description,
    required super.createdAt,
    super.updatedAt,
  });

  factory ExerciseLibraryModel.fromEntity(ExerciseLibraryEntity entity) {
    return ExerciseLibraryModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      muscleGroup: entity.muscleGroup,
      description: entity.description,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ExerciseLibraryModel.fromJson(Map<String, dynamic> json) {
    return ExerciseLibraryModel(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      name: json['name'] as String,
      muscleGroup: json['muscleGroup'] as String,
      description: json['description'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'] as String)
          : (json['createdAt'] as dynamic).toDate(),
      updatedAt: json['updatedAt'] == null
          ? null
          : (json['updatedAt'] is String
              ? DateTime.parse(json['updatedAt'] as String)
              : (json['updatedAt'] as dynamic).toDate()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'userId': userId,
      'name': name,
      'muscleGroup': muscleGroup,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ExerciseLibraryEntity toEntity() {
    return ExerciseLibraryEntity(
      id: id,
      userId: userId,
      name: name,
      muscleGroup: muscleGroup,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
