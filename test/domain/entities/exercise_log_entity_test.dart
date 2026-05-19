import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/domain/entities/exercise_log_entity.dart';
import 'package:workout_tracker/domain/entities/set_log_entity.dart';

ExerciseLogEntity _logWith(List<SetLogEntity> sets) => ExerciseLogEntity(
      exerciseId: 'ex1',
      exerciseName: 'Squat',
      muscleGroup: 'Legs',
      sets: sets,
    );

void main() {
  group('ExerciseLogEntity', () {
    test('totalVolume sums set volumes', () {
      final log = _logWith(const [
        SetLogEntity(setNumber: 1, weight: 50, reps: 10, unit: 'kg'),
        SetLogEntity(setNumber: 2, weight: 60, reps: 8, unit: 'kg'),
      ]);
      expect(log.totalVolume, 50 * 10 + 60 * 8);
    });

    test('totalVolume is 0 for empty sets', () {
      final log = _logWith(const []);
      expect(log.totalVolume, 0.0);
    });

    test('maxWeight returns the highest weight', () {
      final log = _logWith(const [
        SetLogEntity(setNumber: 1, weight: 50, reps: 10, unit: 'kg'),
        SetLogEntity(setNumber: 2, weight: 70, reps: 5, unit: 'kg'),
        SetLogEntity(setNumber: 3, weight: 60, reps: 8, unit: 'kg'),
      ]);
      expect(log.maxWeight, 70);
    });

    test('maxWeight returns 0 for empty sets', () {
      expect(_logWith(const []).maxWeight, 0.0);
    });

    test('maxReps returns the highest rep count', () {
      final log = _logWith(const [
        SetLogEntity(setNumber: 1, weight: 50, reps: 10, unit: 'kg'),
        SetLogEntity(setNumber: 2, weight: 60, reps: 12, unit: 'kg'),
      ]);
      expect(log.maxReps, 12);
    });

    test('maxReps returns 0 for empty sets', () {
      expect(_logWith(const []).maxReps, 0);
    });

    test('completedSetsCount counts only completed sets', () {
      final log = _logWith(const [
        SetLogEntity(setNumber: 1, weight: 50, reps: 10, unit: 'kg', isCompleted: true),
        SetLogEntity(setNumber: 2, weight: 60, reps: 8, unit: 'kg'),
        SetLogEntity(setNumber: 3, weight: 60, reps: 8, unit: 'kg', isCompleted: true),
      ]);
      expect(log.completedSetsCount, 2);
    });

    test('equality is based on exerciseId', () {
      const a = ExerciseLogEntity(
        exerciseId: 'x',
        exerciseName: 'A',
        muscleGroup: 'Legs',
        sets: [],
      );
      const b = ExerciseLogEntity(
        exerciseId: 'x',
        exerciseName: 'B',
        muscleGroup: 'Chest',
        sets: [],
      );
      expect(a, equals(b));
    });
  });
}
