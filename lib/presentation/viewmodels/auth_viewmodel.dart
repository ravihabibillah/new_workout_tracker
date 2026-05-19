import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/remote/firebase_auth_datasource.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'program_viewmodel.dart';

part 'auth_viewmodel.g.dart';

/// Auth repository provider
@riverpod
IAuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(
    dataSource: FirebaseAuthDataSource(
      firebaseAuth: FirebaseAuth.instance,
      googleSignIn: GoogleSignIn(),
      firestore: FirebaseFirestore.instance,
    ),
  );
}

/// Auth state provider
@riverpod
class AuthViewModel extends _$AuthViewModel {
  @override
  Stream<UserEntity?> build() {
    final repository = ref.watch(authRepositoryProvider);
    return repository.authStateChanges();
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithGoogle();
    } on AuthFailure catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Failed to sign in: $e';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signOut();
      // Clear per-user cached data so the next user doesn't see stale programs.
      await ref.read(programCacheProvider).clear();
    } on AuthFailure catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Failed to sign out: $e';
    }
  }

  /// Update user preferences
  Future<void> updatePreferences({
    String? preferredUnit,
    int? defaultRestTime,
  }) async {
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.updateUserPreferences(
        preferredUnit: preferredUnit,
        defaultRestTime: defaultRestTime,
      );
    } on AuthFailure catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Failed to update preferences: $e';
    }
  }
}

/// Current user provider
@riverpod
UserEntity? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authViewModelProvider);
  return authState.value;
}

/// Is authenticated provider
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
}
