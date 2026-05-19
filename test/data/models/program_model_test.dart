import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/models/exercise_model.dart';
import 'package:workout_tracker/data/models/program_model.dart';
import 'package:workout_tracker/domain/entities/exercise_entity.dart';
import 'package:workout_tracker/domain/entities/program_entity.dart';

void main() {
  group('ProgramModel', () {
    final createdAt = DateTime(2026, 5, 1);
    final updatedAt = DateTime(2026, 5, 10);
    final json = {
      'id': 'p1',
      'userId': 'u1',
      'name': 'Push Day',
      'description': 'Chest and shoulders',
      'exercises': [
        {'id': 'e1', 'name': 'Bench Press', 'muscleGroup': 'Chest', 'order': 0},
        {'id': 'e2', 'name': 'OHP', 'muscleGroup': 'Shoulders', 'order': 1},
      ],
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'useRestTimer': true,
      'restTimerDuration': 120,
    };

    test('fromJson parses all fields including nested exercises', () {
      final model = ProgramModel.fromJson(json);
      expect(model.id, 'p1');
      expect(model.userId, 'u1');
      expect(model.name, 'Push Day');
      expect(model.description, 'Chest and shoulders');
      expect(model.exercises.length, 2);
      expect(model.exercises[0].name, 'Bench Press');
      expect(model.createdAt, createdAt);
      expect(model.updatedAt, updatedAt);
      expect(model.useRestTimer, true);
      expect(model.restTimerDuration, 120);
    });

    test('fromJson uses defaults for missing optional fields', () {
      final model = ProgramModel.fromJson({
        'id': 'p1',
        'userId': 'u1',
        'name': 'Test',
        'exercises': <Map<String, dynamic>>[],
        'createdAt': createdAt.toIso8601String(),
      });
      expect(model.description, isNull);
      expect(model.updatedAt, isNull);
      expect(model.useRestTimer, false);
      expect(model.restTimerDuration, 90);
    });

    test('toJson produces correct map', () {
      final model = ProgramModel(
        id: 'p1',
        userId: 'u1',
        name: 'Push Day',
        description: 'Desc',
        exercises: const [
          ExerciseModel(id: 'e1', name: 'Bench', muscleGroup: 'Chest', order: 0),
        ],
        createdAt: createdAt,
        updatedAt: updatedAt,
        useRestTimer: true,
        restTimerDuration: 60,
      );
      final result = model.toJson();
      expect(result['id'], 'p1');
      expect(result['userId'], 'u1');
      expect(result['name'], 'Push Day');
      expect(result['description'], 'Desc');
      expect(result['exercises'], isA<List>());
      expect((result['exercises'] as List).length, 1);
      expect(result['createdAt'], createdAt.toIso8601String());
      expect(result['updatedAt'], updatedAt.toIso8601String());
      expect(result['useRestTimer'], true);
      expect(result['restTimerDuration'], 60);
    });

    test('fromEntity creates model from entity', () {
      final entity = ProgramEntity(
        id: 'p1',
        userId: 'u1',
        name: 'Pull Day',
        exercises: const [
          ExerciseEntity(id: 'e1', name: 'Row', muscleGroup: 'Back', order: 0),
        ],
        createdAt: createdAt,
      );
      final model = ProgramModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.name, entity.name);
      expect(model.exercises.length, 1);
    });

    test('toEntity creates entity from model', () {
      final model = ProgramModel(
        id: 'p1',
        userId: 'u1',
        name: 'Legs',
        exercises: const [
          ExerciseModel(id: 'e1', name: 'Squat', muscleGroup: 'Legs', order: 0),
        ],
        createdAt: createdAt,
      );
      final entity = model.toEntity();
      expect(entity, isA<ProgramEntity>());
      expect(entity.id, 'p1');
      expect(entity.exerciseCount, 1);
    });

    test('roundtrip: entity -> model -> json -> model -> entity', () {
      final original = ProgramEntity(
        id: 'p1',
        userId: 'u1',
        name: 'Full Body',
        description: 'All muscles',
        exercises: const [
          ExerciseEntity(id: 'e1', name: 'Squat', muscleGroup: 'Legs', order: 0),
          ExerciseEntity(id: 'e2', name: 'Bench', muscleGroup: 'Chest', order: 1),
        ],
        createdAt: createdAt,
        updatedAt: updatedAt,
        useRestTimer: true,
        restTimerDuration: 90,
      );
      final model = ProgramModel.fromEntity(original);
      final json = model.toJson();
      final restored = ProgramModel.fromJson(json);
      final entity = restored.toEntity();
      expect(entity.id, original.id);
      expect(entity.name, original.name);
      expect(entity.description, original.description);
      expect(entity.exercises.length, original.exercises.length);
      expect(entity.useRestTimer, original.useRestTimer);
      expect(entity.restTimerDuration, original.restTimerDuration);
    });
  });
}
