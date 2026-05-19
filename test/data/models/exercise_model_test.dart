import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/models/exercise_model.dart';
import 'package:workout_tracker/domain/entities/exercise_entity.dart';

void main() {
  group('ExerciseModel', () {
    const json = {
      'id': 'e1',
      'name': 'Squat',
      'muscleGroup': 'Legs',
      'order': 0,
    };

    test('fromJson parses all fields', () {
      final model = ExerciseModel.fromJson(json);
      expect(model.id, 'e1');
      expect(model.name, 'Squat');
      expect(model.muscleGroup, 'Legs');
      expect(model.order, 0);
    });

    test('toJson produces correct map', () {
      const model = ExerciseModel(
        id: 'e1',
        name: 'Squat',
        muscleGroup: 'Legs',
        order: 0,
      );
      final result = model.toJson();
      expect(result, json);
    });

    test('fromEntity creates model from entity', () {
      const entity = ExerciseEntity(
        id: 'e1',
        name: 'Bench',
        muscleGroup: 'Chest',
        order: 1,
      );
      final model = ExerciseModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.name, entity.name);
      expect(model.muscleGroup, entity.muscleGroup);
      expect(model.order, entity.order);
    });

    test('toEntity creates entity from model', () {
      const model = ExerciseModel(
        id: 'e1',
        name: 'Squat',
        muscleGroup: 'Legs',
        order: 0,
      );
      final entity = model.toEntity();
      expect(entity, isA<ExerciseEntity>());
      expect(entity.id, 'e1');
    });

    test('roundtrip: entity -> model -> json -> model -> entity', () {
      const original = ExerciseEntity(
        id: 'e1',
        name: 'Deadlift',
        muscleGroup: 'Back',
        order: 2,
      );
      final model = ExerciseModel.fromEntity(original);
      final json = model.toJson();
      final restored = ExerciseModel.fromJson(json);
      final entity = restored.toEntity();
      expect(entity.id, original.id);
      expect(entity.name, original.name);
      expect(entity.muscleGroup, original.muscleGroup);
      expect(entity.order, original.order);
    });
  });
}
