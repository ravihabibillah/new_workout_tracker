import '../../domain/entities/workout_session_entity.dart';
import 'exercise_log_model.dart';

/// Workout session model with JSON serialization
class WorkoutSessionModel extends WorkoutSessionEntity {
  const WorkoutSessionModel({
    required super.id,
    required super.userId,
    required super.programId,
    required super.programName,
    required super.startTime,
    super.endTime,
    required super.exerciseLogs,
    super.isCompleted,
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
    );
  }

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      programId: json['programId'] as String,
      programName: json['programName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      exerciseLogs: (json['exerciseLogs'] as List<dynamic>)
          .map((e) => ExerciseLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isCompleted: json['isCompleted'] as bool? ?? false,
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
    );
  }
}
