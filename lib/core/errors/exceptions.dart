/// Base exception class
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException({required super.message, super.code});
}

/// Network exceptions
class NetworkException extends AppException {
  const NetworkException({required super.message, super.code});
}

/// Server exceptions
class ServerException extends AppException {
  const ServerException({required super.message, super.code});
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException({required super.message, super.code});
}

/// Not found exceptions
class NotFoundException extends AppException {
  const NotFoundException({required super.message, super.code});
}
