import '../../domain/entities/workout_session_entity.dart';
import 'exercise_log_model.dart';

/// Workout session model with JSON serialization
class WorkoutSessionModel extends WorkoutSessionEntity {
  const WorkoutSessionModel({
    required super.id,
    required super.userId,
    super.programId,
    super.programName,
    required super.startTime,
    super.endTime,
    required super.exerciseLogs,
    super.isCompleted,
    super.useRestTimer,
    super.restTimerDuration,
    super.isQuickWorkout,
  });

  factory WorkoutSessionModel.fromEntity(WorkoutSessionEntity entity) {
    return WorkoutSessionModel(
      id: entity.id,
      userId: entity.userId,
      programId: entity.programId,
      programName: entity.programName,
      startTime: entity.startTime,
      endTime: entity.endTime,
      exerciseLogs: entity.exerciseLogs
          .map((e) => ExerciseLogModel.fromEntity(e))
          .toList(),
      isCompleted: entity.isCompleted,
      useRestTimer: entity.useRestTimer,
      restTimerDuration: entity.restTimerDuration,
      isQuickWorkout: entity.isQuickWorkout,
    );
  }

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      programId: json['programId'] as String?,
      programName: json['programName'] as String? ?? 'Quick Workout',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      exerciseLogs: (json['exerciseLogs'] as List<dynamic>)
          .map((e) => ExerciseLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      useRestTimer: json['useRestTimer'] as bool? ?? false,
      restTimerDuration: json['restTimerDuration'] as int? ?? 90,
      isQuickWorkout: json['isQuickWorkout'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'programId': programId,
      'programName': programName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'exerciseLogs': exerciseLogs
          .map((e) => (e as ExerciseLogModel).toJson())
          .toList(),
      'isCompleted': isCompleted,
      'useRestTimer': useRestTimer,
      'restTimerDuration': restTimerDuration,
      'isQuickWorkout': isQuickWorkout,
    };
  }

  WorkoutSessionEntity toEntity() {
    return WorkoutSessionEntity(
      id: id,
      userId: userId,
      programId: programId,
      programName: programName,
      startTime: startTime,
      endTime: endTime,
      exerciseLogs: exerciseLogs
          .map((e) => (e as ExerciseLogModel).toEntity())
          .toList(),
      isCompleted: isCompleted,
      useRestTimer: useRestTimer,
      restTimerDuration: restTimerDuration,
      isQuickWorkout: isQuickWorkout,
    );
  }
}
