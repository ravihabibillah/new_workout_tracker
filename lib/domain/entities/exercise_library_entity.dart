/// Exercise library entity - global reusable exercise definition.
/// `userId` is optional and only set when the exercise was created by a user
/// (vs. seeded as default data).
class ExerciseLibraryEntity {
  final String id;
  final String? userId;
  final String name;
  final String muscleGroup;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ExerciseLibraryEntity({
    required this.id,
    this.userId,
    required this.name,
    required this.muscleGroup,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  ExerciseLibraryEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? muscleGroup,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExerciseLibraryEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseLibraryEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ExerciseLibraryEntity(id: $id, name: $name, muscleGroup: $muscleGroup)';
  }
}
