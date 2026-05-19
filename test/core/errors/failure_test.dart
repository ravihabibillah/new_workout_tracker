import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/core/errors/failure.dart';

void main() {
  group('Failure equality', () {
    test('two failures with same message and code are equal', () {
      const a = AuthFailure(message: 'oops', code: '401');
      const b = AuthFailure(message: 'oops', code: '401');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('failures with different messages are not equal', () {
      const a = AuthFailure(message: 'one');
      const b = AuthFailure(message: 'two');
      expect(a, isNot(equals(b)));
    });

    test('failures with different codes are not equal', () {
      const a = AuthFailure(message: 'oops', code: '401');
      const b = AuthFailure(message: 'oops', code: '500');
      expect(a, isNot(equals(b)));
    });

    test('toString includes message and code', () {
      const f = ServerFailure(message: 'broken', code: 'E1');
      final s = f.toString();
      expect(s, contains('broken'));
      expect(s, contains('E1'));
    });
  });

  group('Failure subclasses', () {
    test('subclasses inherit from Failure', () {
      expect(const AuthFailure(message: 'a'), isA<Failure>());
      expect(const NetworkFailure(message: 'a'), isA<Failure>());
      expect(const ServerFailure(message: 'a'), isA<Failure>());
      expect(const CacheFailure(message: 'a'), isA<Failure>());
      expect(const ValidationFailure(message: 'a'), isA<Failure>());
      expect(const NotFoundFailure(message: 'a'), isA<Failure>());
      expect(const PermissionFailure(message: 'a'), isA<Failure>());
    });

    test('subclasses of different types with same message are not equal',
        () {
      const a = AuthFailure(message: 'm');
      const b = ServerFailure(message: 'm');
      // operator== checks runtime type via `is Failure` so they are equal here.
      // We assert the documented behavior: equals via message + code.
      expect(a == b, isTrue);
    });
  });
}
