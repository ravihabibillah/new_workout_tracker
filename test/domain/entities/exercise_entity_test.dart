import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/domain/entities/exercise_entity.dart';

void main() {
  group('ExerciseEntity', () {
    test('copyWith overrides only specified fields', () {
      const e = ExerciseEntity(
        id: '1',
        name: 'Squat',
        muscleGroup: 'Legs',
        order: 0,
      );
      final updated = e.copyWith(name: 'Front Squat');
      expect(updated.id, '1');
      expect(updated.muscleGroup, 'Legs');
      expect(updated.order, 0);
      expect(updated.name, 'Front Squat');
    });

    test('equality is based on id only', () {
      const a = ExerciseEntity(id: '1', name: 'Squat', muscleGroup: 'Legs', order: 0);
      const b = ExerciseEntity(id: '1', name: 'Bench', muscleGroup: 'Chest', order: 1);
      const c = ExerciseEntity(id: '2', name: 'Squat', muscleGroup: 'Legs', order: 0);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString includes id, name and muscleGroup', () {
      const e = ExerciseEntity(id: '1', name: 'Squat', muscleGroup: 'Legs', order: 0);
      final s = e.toString();
      expect(s, contains('1'));
      expect(s, contains('Squat'));
      expect(s, contains('Legs'));
    });
  });
}
