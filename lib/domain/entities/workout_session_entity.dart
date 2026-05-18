import 'exercise_log_entity.dart';

/// Workout session entity - represents a complete workout session
class WorkoutSessionEntity {
  final String id;
  final String userId;
  final String programId;
  final String programName;
  final DateTime startTime;
  final DateTime? endTime;
  final List<ExerciseLogEntity> exerciseLogs;
  final bool isCompleted;

  const WorkoutSessionEntity({
    required this.id,
    required this.userId,
    required this.programId,
    required this.programName,
    required this.startTime,
    this.endTime,
    required this.exerciseLogs,
    this.isCompleted = false,
  });

  WorkoutSessionEntity copyWith({
    String? id,
    String? userId,
    String? programId,
    String? programName,
    DateTime? startTime,
    DateTime? endTime,
    List<ExerciseLogEntity>? exerciseLogs,
    bool? isCompleted,
  }) {
    return WorkoutSessionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Calculate workout duration
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  /// Calculate total volume for entire workout
  double get totalVolume {
    return exerciseLogs.fold(0.0, (sum, log) => sum + log.totalVolume);
  }

  /// Get total number of sets
  int get totalSets {
    return exerciseLogs.fold(0, (sum, log) => sum + log.sets.length);
  }

  /// Get total number of completed sets
  int get completedSets {
    return exerciseLogs.fold(0, (sum, log) => sum + log.completedSetsCount);
  }

  /// Check if workout is in progress
  bool get isInProgress => !isCompleted && endTime == null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutSessionEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WorkoutSessionEntity(id: $id, program: $programName, exercises: ${exerciseLogs.length})';
  }
}
