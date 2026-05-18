import '../../domain/entities/program_entity.dart';
import 'exercise_model.dart';

/// Program model with JSON serialization
class ProgramModel extends ProgramEntity {
  const ProgramModel({
    required super.id,
    required super.userId,
    required super.name,
    super.description,
    required super.exercises,
    required super.createdAt,
    super.updatedAt,
  });

  factory ProgramModel.fromEntity(ProgramEntity entity) {
    return ProgramModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      description: entity.description,
      exercises: entity.exercises
          .map((e) => ExerciseModel.fromEntity(e))
          .toList(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    return ProgramModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'exercises': exercises
          .map((e) => (e as ExerciseModel).toJson())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ProgramEntity toEntity() {
    return ProgramEntity(
      id: id,
      userId: userId,
      name: name,
      description: description,
      exercises: exercises
          .map((e) => (e as ExerciseModel).toEntity())
          .toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
