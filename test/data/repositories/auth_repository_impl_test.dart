import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:workout_tracker/core/errors/exceptions.dart';
import 'package:workout_tracker/core/errors/failure.dart';
import 'package:workout_tracker/data/datasources/remote/firebase_auth_datasource.dart';
import 'package:workout_tracker/data/models/user_model.dart';
import 'package:workout_tracker/data/repositories/auth_repository_impl.dart';
import 'package:workout_tracker/domain/entities/user_entity.dart';

@GenerateNiceMocks([MockSpec<FirebaseAuthDataSource>()])
import 'auth_repository_impl_test.mocks.dart';

void main() {
  late MockFirebaseAuthDataSource mockDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockFirebaseAuthDataSource();
    repository = AuthRepositoryImpl(dataSource: mockDataSource);
  });

  const userModel = UserModel(
    id: 'u1',
    email: 'test@example.com',
    displayName: 'Test User',
  );

  group('AuthRepositoryImpl.getCurrentUser', () {
    test('returns UserEntity when datasource returns a model', () async {
      when(mockDataSource.getCurrentUser())
          .thenAnswer((_) async => userModel);

      final result = await repository.getCurrentUser();

      expect(result, isA<UserEntity>());
      expect(result?.id, 'u1');
      expect(result?.email, 'test@example.com');
    });

    test('returns null when datasource returns null', () async {
      when(mockDataSource.getCurrentUser()).thenAnswer((_) async => null);

      final result = await repository.getCurrentUser();

      expect(result, isNull);
    });

    test('throws AuthFailure when datasource throws AuthException', () async {
      when(mockDataSource.getCurrentUser())
          .thenThrow(const AuthException(message: 'Not signed in', code: '401'));

      expect(
        () => repository.getCurrentUser(),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('throws AuthFailure for unexpected exceptions', () async {
      when(mockDataSource.getCurrentUser()).thenThrow(Exception('unexpected'));

      expect(
        () => repository.getCurrentUser(),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  group('AuthRepositoryImpl.signInWithGoogle', () {
    test('returns UserEntity on success', () async {
      when(mockDataSource.signInWithGoogle())
          .thenAnswer((_) async => userModel);

      final result = await repository.signInWithGoogle();

      expect(result, isA<UserEntity>());
      expect(result.id, 'u1');
    });

    test('throws AuthFailure when datasource throws AuthException', () async {
      when(mockDataSource.signInWithGoogle())
          .thenThrow(const AuthException(message: 'Sign in cancelled'));

      expect(
        () => repository.signInWithGoogle(),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  group('AuthRepositoryImpl.signOut', () {
    test('completes without error on success', () async {
      when(mockDataSource.signOut()).thenAnswer((_) async {});

      await expectLater(repository.signOut(), completes);
      verify(mockDataSource.signOut()).called(1);
    });

    test('throws AuthFailure when datasource throws AuthException', () async {
      when(mockDataSource.signOut())
          .thenThrow(const AuthException(message: 'Sign out failed'));

      expect(
        () => repository.signOut(),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  group('AuthRepositoryImpl.authStateChanges', () {
    test('maps UserModel stream to UserEntity stream', () {
      when(mockDataSource.authStateChanges())
          .thenAnswer((_) => Stream.value(userModel));

      final stream = repository.authStateChanges();

      expect(stream, emits(isA<UserEntity>()));
    });

    test('maps null values in stream', () {
      when(mockDataSource.authStateChanges())
          .thenAnswer((_) => Stream.value(null));

      final stream = repository.authStateChanges();

      expect(stream, emits(isNull));
    });
  });

  group('AuthRepositoryImpl.updateUserPreferences', () {
    test('completes without error on success', () async {
      when(mockDataSource.updateUserPreferences(
        preferredUnit: 'lbs',
        defaultRestTime: 60,
      )).thenAnswer((_) async {});

      await expectLater(
        repository.updateUserPreferences(
          preferredUnit: 'lbs',
          defaultRestTime: 60,
        ),
        completes,
      );
    });

    test('throws AuthFailure when datasource throws AuthException', () async {
      when(mockDataSource.updateUserPreferences(
        preferredUnit: anyNamed('preferredUnit'),
        defaultRestTime: anyNamed('defaultRestTime'),
      )).thenThrow(const AuthException(message: 'Update failed'));

      expect(
        () => repository.updateUserPreferences(preferredUnit: 'lbs'),
        throwsA(isA<AuthFailure>()),
      );
    });
  });
}
