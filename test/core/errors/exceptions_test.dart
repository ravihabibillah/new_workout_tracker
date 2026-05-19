import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/core/errors/exceptions.dart';

void main() {
  group('AppException', () {
    test('toString includes message and code', () {
      const e = AppException(message: 'failed', code: 'E1');
      final s = e.toString();
      expect(s, contains('failed'));
      expect(s, contains('E1'));
    });

    test('subclasses are AppException', () {
      expect(const AuthException(message: 'a'), isA<AppException>());
      expect(const NetworkException(message: 'a'), isA<AppException>());
      expect(const ServerException(message: 'a'), isA<AppException>());
      expect(const CacheException(message: 'a'), isA<AppException>());
      expect(const NotFoundException(message: 'a'), isA<AppException>());
    });

    test('subclasses preserve message and code', () {
      const e = ServerException(message: 'server down', code: '500');
      expect(e.message, 'server down');
      expect(e.code, '500');
    });
  });
}
