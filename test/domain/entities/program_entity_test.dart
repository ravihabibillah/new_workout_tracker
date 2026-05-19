import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/domain/entities/exercise_entity.dart';
import 'package:workout_tracker/domain/entities/program_entity.dart';

void main() {
  group('ProgramEntity', () {
    test('exerciseCount and isEmpty reflect exercises list', () {
      final empty = ProgramEntity(
        id: 'p1',
        userId: 'u1',
        name: 'Empty',
        exercises: const [],
        createdAt: DateTime(2026, 5, 1),
      );
      expect(empty.exerciseCount, 0);
      expect(empty.isEmpty, true);

      final filled = ProgramEntity(
        id: 'p2',
        userId: 'u1',
        name: 'Full',
        exercises: const [
          ExerciseEntity(id: 'e1', name: 'Squat', muscleGroup: 'Legs', order: 0),
          ExerciseEntity(id: 'e2', name: 'Bench', muscleGroup: 'Chest', order: 1),
        ],
        createdAt: DateTime(2026, 5, 1),
      );
      expect(filled.exerciseCount, 2);
      expect(filled.isEmpty, false);
    });

    test('copyWith overrides only specified fields', () {
      final original = ProgramEntity(
        id: 'p1',
        userId: 'u1',
        name: 'Push',
        exercises: const [],
        createdAt: DateTime(2026, 5, 1),
        useRestTimer: false,
        restTimerDuration: 90,
      );
      final updated = original.copyWith(name: 'Push Day', useRestTimer: true);
      expect(updated.id, 'p1');
      expect(updated.name, 'Push Day');
      expect(updated.useRestTimer, true);
      expect(updated.restTimerDuration, 90);
    });

    test('equality is based on id', () {
      final a = ProgramEntity(
        id: 'p1',
        userId: 'u1',
        name: 'A',
        exercises: const [],
        createdAt: DateTime(2026, 5, 1),
      );
      final b = ProgramEntity(
        id: 'p1',
        userId: 'u2',
        name: 'B',
        exercises: const [],
        createdAt: DateTime(2026, 5, 2),
      );
      expect(a, equals(b));
    });

    test('default values for useRestTimer and restTimerDuration', () {
      final p = ProgramEntity(
        id: 'p1',
        userId: 'u1',
        name: 'X',
        exercises: const [],
        createdAt: DateTime(2026, 5, 1),
      );
      expect(p.useRestTimer, false);
      expect(p.restTimerDuration, 90);
    });
  });
}
