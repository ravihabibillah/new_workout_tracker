import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/models/exercise_log_model.dart';
import 'package:workout_tracker/data/models/set_log_model.dart';
import 'package:workout_tracker/domain/entities/exercise_log_entity.dart';
import 'package:workout_tracker/domain/entities/set_log_entity.dart';

void main() {
  group('ExerciseLogModel', () {
    final json = {
      'exerciseId': 'ex1',
      'exerciseName': 'Squat',
      'muscleGroup': 'Legs',
      'sets': [
        {'setNumber': 1, 'weight': 50.0, 'reps': 10, 'unit': 'kg', 'isCompleted': true},
        {'setNumber': 2, 'weight': 55.0, 'reps': 8, 'unit': 'kg', 'isCompleted': false},
      ],
    };

    test('fromJson parses all fields including nested sets', () {
      final model = ExerciseLogModel.fromJson(json);
      expect(model.exerciseId, 'ex1');
      expect(model.exerciseName, 'Squat');
      expect(model.muscleGroup, 'Legs');
      expect(model.sets.length, 2);
      expect(model.sets[0].weight, 50.0);
      expect(model.sets[1].reps, 8);
    });

    test('toJson produces correct map with nested sets', () {
      const model = ExerciseLogModel(
        exerciseId: 'ex1',
        exerciseName: 'Squat',
        muscleGroup: 'Legs',
        sets: [
          SetLogModel(setNumber: 1, weight: 50.0, reps: 10, unit: 'kg'),
        ],
      );
      final result = model.toJson();
      expect(result['exerciseId'], 'ex1');
      expect(result['exerciseName'], 'Squat');
      expect(result['muscleGroup'], 'Legs');
      expect(result['sets'], isA<List>());
      expect((result['sets'] as List).length, 1);
    });

    test('fromEntity creates model from entity', () {
      const entity = ExerciseLogEntity(
        exerciseId: 'ex1',
        exerciseName: 'Bench',
        muscleGroup: 'Chest',
        sets: [
          SetLogEntity(setNumber: 1, weight: 40.0, reps: 12, unit: 'kg'),
        ],
      );
      final model = ExerciseLogModel.fromEntity(entity);
      expect(model.exerciseId, entity.exerciseId);
      expect(model.exerciseName, entity.exerciseName);
      expect(model.sets.length, 1);
    });

    test('toEntity creates entity from model', () {
      const model = ExerciseLogModel(
        exerciseId: 'ex1',
        exerciseName: 'Squat',
        muscleGroup: 'Legs',
        sets: [
          SetLogModel(setNumber: 1, weight: 50.0, reps: 10, unit: 'kg'),
        ],
      );
      final entity = model.toEntity();
      expect(entity, isA<ExerciseLogEntity>());
      expect(entity.exerciseId, 'ex1');
      expect(entity.sets.length, 1);
      expect(entity.totalVolume, 500.0);
    });

    test('roundtrip: entity -> model -> json -> model -> entity', () {
      const original = ExerciseLogEntity(
        exerciseId: 'ex1',
        exerciseName: 'Deadlift',
        muscleGroup: 'Back',
        sets: [
          SetLogEntity(setNumber: 1, weight: 100.0, reps: 5, unit: 'kg', isCompleted: true),
          SetLogEntity(setNumber: 2, weight: 110.0, reps: 3, unit: 'kg'),
        ],
      );
      final model = ExerciseLogModel.fromEntity(original);
      final json = model.toJson();
      final restored = ExerciseLogModel.fromJson(json);
      final entity = restored.toEntity();
      expect(entity.exerciseId, original.exerciseId);
      expect(entity.exerciseName, original.exerciseName);
      expect(entity.muscleGroup, original.muscleGroup);
      expect(entity.sets.length, original.sets.length);
      expect(entity.sets[0].weight, original.sets[0].weight);
      expect(entity.sets[1].reps, original.sets[1].reps);
    });
  });
}
