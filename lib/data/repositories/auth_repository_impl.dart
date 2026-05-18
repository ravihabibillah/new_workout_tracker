import '../../core/errors/exceptions.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/remote/firebase_auth_datasource.dart';

/// Authentication repository implementation
class AuthRepositoryImpl implements IAuthRepository {
  final FirebaseAuthDataSource _dataSource;

  AuthRepositoryImpl({required FirebaseAuthDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final userModel = await _dataSource.getCurrentUser();
      return userModel?.toEntity();
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, code: e.code);
    } catch (e) {
      throw AuthFailure(message: 'Failed to get current user: $e');
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      final userModel = await _dataSource.signInWithGoogle();
      return userModel.toEntity();
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, code: e.code);
    } catch (e) {
      throw AuthFailure(message: 'Failed to sign in with Google: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _dataSource.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, code: e.code);
    } catch (e) {
      throw AuthFailure(message: 'Failed to sign out: $e');
    }
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    try {
      return _dataSource.authStateChanges().map((userModel) {
        return userModel?.toEntity();
      });
    } catch (e) {
      throw AuthFailure(message: 'Failed to watch auth state: $e');
    }
  }

  @override
  Future<void> updateUserPreferences({
    String? preferredUnit,
    int? defaultRestTime,
  }) async {
    try {
      await _dataSource.updateUserPreferences(
        preferredUnit: preferredUnit,
        defaultRestTime: defaultRestTime,
      );
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, code: e.code);
    } catch (e) {
      throw AuthFailure(message: 'Failed to update preferences: $e');
    }
  }
}
