/// Exercise entity - pure domain model
class ExerciseEntity {
  final String id;
  final String name;
  final String muscleGroup;
  final int order;

  const ExerciseEntity({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.order,
  });

  ExerciseEntity copyWith({
    String? id,
    String? name,
    String? muscleGroup,
    int? order,
  }) {
    return ExerciseEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ExerciseEntity(id: $id, name: $name, muscleGroup: $muscleGroup)';
  }
}
