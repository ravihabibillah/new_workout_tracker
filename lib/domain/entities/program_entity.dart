import 'exercise_entity.dart';

/// Program entity - represents a workout program
class ProgramEntity {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<ExerciseEntity> exercises;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProgramEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.exercises,
    required this.createdAt,
    this.updatedAt,
  });

  ProgramEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<ExerciseEntity>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgramEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get exercise count
  int get exerciseCount => exercises.length;

  /// Check if program is empty
  bool get isEmpty => exercises.isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgramEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProgramEntity(id: $id, name: $name, exercises: ${exercises.length})';
  }
}
