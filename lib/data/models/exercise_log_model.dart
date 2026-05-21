import '../../domain/entities/exercise_log_entity.dart';
import 'set_log_model.dart';

/// Exercise log model with JSON serialization
class ExerciseLogModel extends ExerciseLogEntity {
  const ExerciseLogModel({
    required super.exerciseId,
    required super.exerciseName,
    required super.muscleGroup,
    required super.sets,
  });

  factory ExerciseLogModel.fromEntity(ExerciseLogEntity entity) {
    return ExerciseLogModel(
      exerciseId: entity.exerciseId,
      exerciseName: entity.exerciseName,
      muscleGroup: entity.muscleGroup,
      sets: entity.sets.map((s) => SetLogModel.fromEntity(s)).toList(),
    );
  }

  factory ExerciseLogModel.fromJson(Map<String, dynamic> json) {
    return ExerciseLogModel(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      muscleGroup: json['muscleGroup'] as String,
      sets: (json['sets'] as List<dynamic>)
          .map((s) => SetLogModel.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'muscleGroup': muscleGroup,
      'sets': sets.map((s) => (s as SetLogModel).toJson()).toList(),
    };
  }

  ExerciseLogEntity toEntity() {
    return ExerciseLogEntity(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      muscleGroup: muscleGroup,
      sets: sets.map((s) => (s as SetLogModel).toEntity()).toList(),
    );
  }
}
