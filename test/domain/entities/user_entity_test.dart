import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    test('has default values for preferredUnit and defaultRestTime', () {
      const u = UserEntity(id: '1', email: 'a@b.c');
      expect(u.preferredUnit, 'kg');
      expect(u.defaultRestTime, 90);
      expect(u.displayName, isNull);
      expect(u.photoUrl, isNull);
    });

    test('copyWith overrides only specified fields', () {
      const u = UserEntity(id: '1', email: 'a@b.c', displayName: 'Alice');
      final updated = u.copyWith(displayName: 'Bob');
      expect(updated.id, '1');
      expect(updated.email, 'a@b.c');
      expect(updated.displayName, 'Bob');
    });

    test('copyWith preserves preferredUnit when not provided', () {
      const u = UserEntity(id: '1', email: 'a@b.c', preferredUnit: 'lbs');
      final updated = u.copyWith(displayName: 'Bob');
      expect(updated.preferredUnit, 'lbs');
    });

    test('equality is based on id', () {
      const a = UserEntity(id: '1', email: 'a@b.c');
      const b = UserEntity(id: '1', email: 'different@b.c');
      const c = UserEntity(id: '2', email: 'a@b.c');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString includes id, email and displayName', () {
      const u = UserEntity(id: '1', email: 'a@b.c', displayName: 'Alice');
      final s = u.toString();
      expect(s, contains('1'));
      expect(s, contains('a@b.c'));
      expect(s, contains('Alice'));
    });
  });
}
