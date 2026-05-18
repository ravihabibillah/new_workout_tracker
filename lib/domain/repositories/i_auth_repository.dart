import '../entities/user_entity.dart';

/// Authentication repository interface
abstract class IAuthRepository {
  /// Get current authenticated user
  Future<UserEntity?> getCurrentUser();

  /// Sign in with Google
  Future<UserEntity> signInWithGoogle();

  /// Sign out
  Future<void> signOut();

  /// Stream of auth state changes
  Stream<UserEntity?> authStateChanges();

  /// Update user preferences
  Future<void> updateUserPreferences({
    String? preferredUnit,
    int? defaultRestTime,
  });
}
