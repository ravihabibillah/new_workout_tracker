import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/models/exercise_library_model.dart';
import 'package:workout_tracker/domain/entities/exercise_library_entity.dart';

void main() {
  group('ExerciseLibraryModel', () {
    final createdAt = DateTime(2026, 5, 1);
    final updatedAt = DateTime(2026, 5, 10);
    final json = {
      'id': 'ex1',
      'userId': 'u1',
      'name': 'Squat',
      'muscleGroup': 'Legs',
      'description': 'A compound leg exercise',
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    test('fromJson parses all fields with ISO string dates', () {
      final model = ExerciseLibraryModel.fromJson(json);
      expect(model.id, 'ex1');
      expect(model.userId, 'u1');
      expect(model.name, 'Squat');
      expect(model.muscleGroup, 'Legs');
      expect(model.description, 'A compound leg exercise');
      expect(model.createdAt, createdAt);
      expect(model.updatedAt, updatedAt);
    });

    test('fromJson handles null optional fields', () {
      final model = ExerciseLibraryModel.fromJson({
        'id': 'ex1',
        'name': 'Bench',
        'muscleGroup': 'Chest',
        'createdAt': createdAt.toIso8601String(),
      });
      expect(model.userId, isNull);
      expect(model.description, isNull);
      expect(model.updatedAt, isNull);
    });

    test('toJson produces correct map', () {
      final model = ExerciseLibraryModel(
        id: 'ex1',
        userId: 'u1',
        name: 'Squat',
        muscleGroup: 'Legs',
        description: 'Desc',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final result = model.toJson();
      expect(result['userId'], 'u1');
      expect(result['name'], 'Squat');
      expect(result['muscleGroup'], 'Legs');
      expect(result['description'], 'Desc');
      expect(result['createdAt'], createdAt.toIso8601String());
      expect(result['updatedAt'], updatedAt.toIso8601String());
    });

    test('toJson omits userId when null', () {
      final model = ExerciseLibraryModel(
        id: 'ex1',
        name: 'Squat',
        muscleGroup: 'Legs',
        createdAt: createdAt,
      );
      final result = model.toJson();
      expect(result.containsKey('userId'), false);
    });

    test('fromEntity creates model from entity', () {
      final entity = ExerciseLibraryEntity(
        id: 'ex1',
        userId: 'u1',
        name: 'Deadlift',
        muscleGroup: 'Back',
        createdAt: createdAt,
      );
      final model = ExerciseLibraryModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.userId, entity.userId);
      expect(model.name, entity.name);
      expect(model.muscleGroup, entity.muscleGroup);
    });

    test('toEntity creates entity from model', () {
      final model = ExerciseLibraryModel(
        id: 'ex1',
        name: 'Squat',
        muscleGroup: 'Legs',
        createdAt: createdAt,
      );
      final entity = model.toEntity();
      expect(entity, isA<ExerciseLibraryEntity>());
      expect(entity.id, 'ex1');
      expect(entity.name, 'Squat');
    });

    test('roundtrip: entity -> model -> json -> model -> entity', () {
      final original = ExerciseLibraryEntity(
        id: 'ex1',
        userId: 'u1',
        name: 'OHP',
        muscleGroup: 'Shoulders',
        description: 'Overhead press',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final model = ExerciseLibraryModel.fromEntity(original);
      final json = model.toJson();
      json['id'] = original.id;
      final restored = ExerciseLibraryModel.fromJson(json);
      final entity = restored.toEntity();
      expect(entity.id, original.id);
      expect(entity.userId, original.userId);
      expect(entity.name, original.name);
      expect(entity.muscleGroup, original.muscleGroup);
      expect(entity.description, original.description);
      expect(entity.createdAt, original.createdAt);
      expect(entity.updatedAt, original.updatedAt);
    });
  });
}
