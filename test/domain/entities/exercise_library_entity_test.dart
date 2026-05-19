import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/domain/entities/exercise_library_entity.dart';

void main() {
  group('ExerciseLibraryEntity', () {
    test('userId is optional and defaults to null', () {
      final e = ExerciseLibraryEntity(
        id: '1',
        name: 'Squat',
        muscleGroup: 'Legs',
        createdAt: DateTime(2026, 5, 1),
      );
      expect(e.userId, isNull);
      expect(e.description, isNull);
      expect(e.updatedAt, isNull);
    });

    test('copyWith overrides only specified fields', () {
      final e = ExerciseLibraryEntity(
        id: '1',
        name: 'Squat',
        muscleGroup: 'Legs',
        createdAt: DateTime(2026, 5, 1),
      );
      final updated = e.copyWith(description: 'A leg exercise');
      expect(updated.description, 'A leg exercise');
      expect(updated.id, '1');
      expect(updated.name, 'Squat');
    });

    test('equality based on id', () {
      final a = ExerciseLibraryEntity(
        id: '1',
        name: 'Squat',
        muscleGroup: 'Legs',
        createdAt: DateTime(2026, 5, 1),
      );
      final b = ExerciseLibraryEntity(
        id: '1',
        name: 'Different',
        muscleGroup: 'Chest',
        createdAt: DateTime(2026, 5, 2),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
