import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/domain/entities/exercise_log_entity.dart';
import 'package:workout_tracker/domain/entities/set_log_entity.dart';
import 'package:workout_tracker/domain/entities/workout_session_entity.dart';

WorkoutSessionEntity _session({
  DateTime? endTime,
  bool isCompleted = false,
  List<ExerciseLogEntity> logs = const [],
}) {
  return WorkoutSessionEntity(
    id: 's1',
    userId: 'u1',
    programId: 'p1',
    programName: 'Push Day',
    startTime: DateTime(2026, 5, 1, 9, 0),
    endTime: endTime,
    exerciseLogs: logs,
    isCompleted: isCompleted,
  );
}

void main() {
  group('WorkoutSessionEntity.duration', () {
    test('returns null when endTime is null', () {
      expect(_session().duration, isNull);
    });

    test('returns the difference between endTime and startTime', () {
      final s = _session(endTime: DateTime(2026, 5, 1, 10, 30));
      expect(s.duration, const Duration(hours: 1, minutes: 30));
    });
  });

  group('WorkoutSessionEntity totals', () {
    test('totalVolume sums all exerciseLog volumes', () {
      final logs = [
        ExerciseLogEntity(
          exerciseId: 'a',
          exerciseName: 'Squat',
          muscleGroup: 'Legs',
          sets: const [
            SetLogEntity(setNumber: 1, weight: 50, reps: 10, unit: 'kg'),
          ],
        ),
        ExerciseLogEntity(
          exerciseId: 'b',
          exerciseName: 'Bench',
          muscleGroup: 'Chest',
          sets: const [
            SetLogEntity(setNumber: 1, weight: 40, reps: 10, unit: 'kg'),
          ],
        ),
      ];
      expect(_session(logs: logs).totalVolume, 500 + 400);
    });

    test('totalSets and completedSets count correctly', () {
      final logs = [
        ExerciseLogEntity(
          exerciseId: 'a',
          exerciseName: 'Squat',
          muscleGroup: 'Legs',
          sets: const [
            SetLogEntity(setNumber: 1, weight: 50, reps: 10, unit: 'kg', isCompleted: true),
            SetLogEntity(setNumber: 2, weight: 50, reps: 10, unit: 'kg'),
          ],
        ),
        ExerciseLogEntity(
          exerciseId: 'b',
          exerciseName: 'Bench',
          muscleGroup: 'Chest',
          sets: const [
            SetLogEntity(setNumber: 1, weight: 40, reps: 10, unit: 'kg', isCompleted: true),
          ],
        ),
      ];
      final session = _session(logs: logs);
      expect(session.totalSets, 3);
      expect(session.completedSets, 2);
    });
  });

  group('WorkoutSessionEntity.isInProgress', () {
    test('returns true when not completed and no endTime', () {
      expect(_session().isInProgress, true);
    });

    test('returns false when completed', () {
      expect(_session(isCompleted: true).isInProgress, false);
    });

    test('returns false when endTime is set', () {
      expect(_session(endTime: DateTime(2026, 5, 1, 10, 0)).isInProgress, false);
    });
  });
}
