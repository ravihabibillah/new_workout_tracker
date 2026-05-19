import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/domain/entities/set_log_entity.dart';

void main() {
  group('SetLogEntity', () {
    test('volume is weight * reps', () {
      const s = SetLogEntity(
        setNumber: 1,
        weight: 50.0,
        reps: 10,
        unit: 'kg',
      );
      expect(s.volume, 500.0);
    });

    test('volume is zero when weight or reps is zero', () {
      const a = SetLogEntity(setNumber: 1, weight: 0, reps: 10, unit: 'kg');
      const b = SetLogEntity(setNumber: 1, weight: 50, reps: 0, unit: 'kg');
      expect(a.volume, 0.0);
      expect(b.volume, 0.0);
    });

    test('isCompleted defaults to false', () {
      const s = SetLogEntity(setNumber: 1, weight: 50, reps: 10, unit: 'kg');
      expect(s.isCompleted, false);
      expect(s.completedAt, isNull);
    });

    test('copyWith overrides specified fields', () {
      const s = SetLogEntity(setNumber: 1, weight: 50, reps: 10, unit: 'kg');
      final updated = s.copyWith(weight: 60, isCompleted: true);
      expect(updated.weight, 60);
      expect(updated.reps, 10);
      expect(updated.isCompleted, true);
    });

    test('equality compares setNumber, weight, reps', () {
      const a = SetLogEntity(setNumber: 1, weight: 50, reps: 10, unit: 'kg');
      const b = SetLogEntity(setNumber: 1, weight: 50, reps: 10, unit: 'lbs');
      const c = SetLogEntity(setNumber: 2, weight: 50, reps: 10, unit: 'kg');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
