import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/core/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('returns error when value is null', () {
      expect(Validators.required(null), isNotNull);
    });

    test('returns error when value is empty string', () {
      expect(Validators.required(''), isNotNull);
    });

    test('returns error when value is whitespace only', () {
      expect(Validators.required('   '), isNotNull);
    });

    test('returns null when value is non-empty', () {
      expect(Validators.required('abc'), isNull);
    });

    test('uses fieldName in error message when provided', () {
      final result = Validators.required(null, fieldName: 'Email');
      expect(result, contains('Email'));
    });
  });

  group('Validators.number', () {
    test('returns error when value is null or empty', () {
      expect(Validators.number(null), isNotNull);
      expect(Validators.number(''), isNotNull);
    });

    test('returns error when value is not a number', () {
      expect(Validators.number('abc'), isNotNull);
    });

    test('returns error when value is negative and allowNegative is false',
        () {
      expect(Validators.number('-5'), isNotNull);
    });

    test('returns null when value is negative and allowNegative is true', () {
      expect(Validators.number('-5', allowNegative: true), isNull);
    });

    test('returns null for valid positive numbers', () {
      expect(Validators.number('10'), isNull);
      expect(Validators.number('10.5'), isNull);
      expect(Validators.number('0'), isNull);
    });
  });

  group('Validators.positiveNumber', () {
    test('returns error when value is null or empty', () {
      expect(Validators.positiveNumber(null), isNotNull);
      expect(Validators.positiveNumber(''), isNotNull);
    });

    test('returns error when value is not a number', () {
      expect(Validators.positiveNumber('abc'), isNotNull);
    });

    test('returns error when value is zero', () {
      expect(Validators.positiveNumber('0'), isNotNull);
    });

    test('returns error when value is negative', () {
      expect(Validators.positiveNumber('-1'), isNotNull);
    });

    test('returns null for positive numbers', () {
      expect(Validators.positiveNumber('5'), isNull);
      expect(Validators.positiveNumber('0.5'), isNull);
    });
  });

  group('Validators.weight', () {
    test('returns null for valid weight', () {
      expect(Validators.weight('20.5'), isNull);
    });

    test('returns error for zero weight', () {
      expect(Validators.weight('0'), isNotNull);
    });

    test('returns error for non-numeric weight', () {
      expect(Validators.weight('heavy'), isNotNull);
    });
  });

  group('Validators.reps', () {
    test('returns null for valid integer reps', () {
      expect(Validators.reps('10'), isNull);
    });

    test('returns error for zero reps', () {
      expect(Validators.reps('0'), isNotNull);
    });

    test('returns error for decimal reps', () {
      expect(Validators.reps('10.5'), 'Reps must be a whole number');
    });

    test('returns error for negative reps', () {
      expect(Validators.reps('-1'), isNotNull);
    });

    test('returns error for empty reps', () {
      expect(Validators.reps(''), isNotNull);
    });
  });

  group('Validators.email', () {
    test('returns error when value is null or empty', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('returns error for invalid email format', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('foo@bar'), isNotNull);
      expect(Validators.email('@example.com'), isNotNull);
      expect(Validators.email('foo @bar.com'), isNotNull);
    });

    test('returns null for valid email format', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('user.name+tag@example.co.id'), isNull);
    });
  });
}
