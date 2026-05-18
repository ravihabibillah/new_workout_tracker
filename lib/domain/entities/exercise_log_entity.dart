import 'set_log_entity.dart';

/// Exercise log entity - represents all sets for an exercise in a workout
class ExerciseLogEntity {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final List<SetLogEntity> sets;

  const ExerciseLogEntity({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.sets,
  });

  ExerciseLogEntity copyWith({
    String? exerciseId,
    String? exerciseName,
    String? muscleGroup,
    List<SetLogEntity>? sets,
  }) {
    return ExerciseLogEntity(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      sets: sets ?? this.sets,
    );
  }

  /// Calculate total volume for this exercise
  double get totalVolume {
    return sets.fold(0.0, (sum, set) => sum + set.volume);
  }

  /// Get max weight lifted
  double get maxWeight {
    if (sets.isEmpty) return 0.0;
    return sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
  }

  /// Get max reps performed
  int get maxReps {
    if (sets.isEmpty) return 0;
    return sets.map((s) => s.reps).reduce((a, b) => a > b ? a : b);
  }

  /// Get number of completed sets
  int get completedSetsCount {
    return sets.where((s) => s.isCompleted).length;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseLogEntity && other.exerciseId == exerciseId;
  }

  @override
  int get hashCode => exerciseId.hashCode;

  @override
  String toString() {
    return 'ExerciseLogEntity(name: $exerciseName, sets: ${sets.length})';
  }
}
