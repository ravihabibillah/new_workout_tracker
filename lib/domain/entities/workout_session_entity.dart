import 'exercise_log_entity.dart';

/// Workout session entity - represents a complete workout session
class WorkoutSessionEntity {
  final String id;
  final String userId;
  final String? programId;
  final String programName;
  final DateTime startTime;
  final DateTime? endTime;
  final List<ExerciseLogEntity> exerciseLogs;
  final bool isCompleted;
  final bool useRestTimer;
  final int restTimerDuration;
  final bool isQuickWorkout;

  const WorkoutSessionEntity({
    required this.id,
    required this.userId,
    this.programId,
    this.programName = 'Quick Workout',
    required this.startTime,
    this.endTime,
    required this.exerciseLogs,
    this.isCompleted = false,
    this.useRestTimer = false,
    this.restTimerDuration = 90,
    this.isQuickWorkout = false,
  });

  WorkoutSessionEntity copyWith({
    String? id,
    String? userId,
    Object? programId = _sentinel,
    String? programName,
    DateTime? startTime,
    DateTime? endTime,
    List<ExerciseLogEntity>? exerciseLogs,
    bool? isCompleted,
    bool? useRestTimer,
    int? restTimerDuration,
    bool? isQuickWorkout,
  }) {
    return WorkoutSessionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      programId: identical(programId, _sentinel)
          ? this.programId
          : programId as String?,
      programName: programName ?? this.programName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
      isCompleted: isCompleted ?? this.isCompleted,
      useRestTimer: useRestTimer ?? this.useRestTimer,
      restTimerDuration: restTimerDuration ?? this.restTimerDuration,
      isQuickWorkout: isQuickWorkout ?? this.isQuickWorkout,
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

const _sentinel = Object();
