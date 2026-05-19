import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:workout_tracker/core/errors/failure.dart';
import 'package:workout_tracker/data/datasources/local/program_cache.dart';
import 'package:workout_tracker/domain/entities/user_entity.dart';
import 'package:workout_tracker/domain/repositories/i_auth_repository.dart';
import 'package:workout_tracker/presentation/viewmodels/auth_viewmodel.dart';
import 'package:workout_tracker/presentation/viewmodels/program_viewmodel.dart';

@GenerateNiceMocks([
  MockSpec<IAuthRepository>(),
  MockSpec<ProgramCache>(),
])
import 'auth_viewmodel_test.mocks.dart';

ProviderContainer _makeContainer(
  IAuthRepository repo, {
  ProgramCache? programCache,
  Stream<UserEntity?>? authStream,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      if (programCache != null)
        programCacheProvider.overrideWithValue(programCache),
    ],
  );
}

void main() {
  late MockIAuthRepository mockRepo;
  late MockProgramCache mockProgramCache;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockIAuthRepository();
    mockProgramCache = MockProgramCache();
    when(mockRepo.authStateChanges())
        .thenAnswer((_) => const Stream<UserEntity?>.empty());
    container = _makeContainer(mockRepo, programCache: mockProgramCache);
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthViewModel.signInWithGoogle', () {
    test('completes when repository succeeds', () async {
      const user = UserEntity(id: 'u1', email: 'a@b.c');
      when(mockRepo.signInWithGoogle()).thenAnswer((_) async => user);

      final notifier = container.read(authViewModelProvider.notifier);
      await expectLater(notifier.signInWithGoogle(), completes);

      verify(mockRepo.signInWithGoogle()).called(1);
    });

    test('throws AuthFailure message when repository fails', () async {
      when(mockRepo.signInWithGoogle())
          .thenThrow(const AuthFailure(message: 'cancelled'));

      final notifier = container.read(authViewModelProvider.notifier);

      expect(
        () => notifier.signInWithGoogle(),
        throwsA('cancelled'),
      );
    });
  });

  group('AuthViewModel.signOut', () {
    test('signs out and clears program cache on success', () async {
      when(mockRepo.signOut()).thenAnswer((_) async {});
      when(mockProgramCache.clear()).thenAnswer((_) async {});

      final notifier = container.read(authViewModelProvider.notifier);
      await notifier.signOut();

      verify(mockRepo.signOut()).called(1);
      verify(mockProgramCache.clear()).called(1);
    });

    test('throws message when repository fails', () async {
      when(mockRepo.signOut())
          .thenThrow(const AuthFailure(message: 'sign out failed'));

      final notifier = container.read(authViewModelProvider.notifier);

      expect(() => notifier.signOut(), throwsA('sign out failed'));
    });
  });

  group('AuthViewModel.updatePreferences', () {
    test('completes on success', () async {
      when(mockRepo.updateUserPreferences(
        preferredUnit: 'lbs',
        defaultRestTime: 60,
      )).thenAnswer((_) async {});

      final notifier = container.read(authViewModelProvider.notifier);
      await expectLater(
        notifier.updatePreferences(preferredUnit: 'lbs', defaultRestTime: 60),
        completes,
      );
    });

    test('throws message when repository fails', () async {
      when(mockRepo.updateUserPreferences(
        preferredUnit: anyNamed('preferredUnit'),
        defaultRestTime: anyNamed('defaultRestTime'),
      )).thenThrow(const AuthFailure(message: 'update failed'));

      final notifier = container.read(authViewModelProvider.notifier);

      expect(
        () => notifier.updatePreferences(preferredUnit: 'lbs'),
        throwsA('update failed'),
      );
    });
  });

  group('currentUserProvider', () {
    test('reads value from authViewModelProvider', () async {
      const user = UserEntity(id: 'u1', email: 'a@b.c');
      when(mockRepo.authStateChanges())
          .thenAnswer((_) => Stream.value(user));

      container.dispose();
      container = _makeContainer(mockRepo, programCache: mockProgramCache);

      // Subscribe to trigger stream listening, then flush.
      container.listen(authViewModelProvider, (_, __) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final result = container.read(currentUserProvider);
      expect(result, user);
    });

    test('returns null when no user', () async {
      when(mockRepo.authStateChanges())
          .thenAnswer((_) => Stream.value(null));

      container.dispose();
      container = _makeContainer(mockRepo, programCache: mockProgramCache);

      container.listen(authViewModelProvider, (_, __) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final result = container.read(currentUserProvider);
      expect(result, isNull);
    });
  });

  group('isAuthenticatedProvider', () {
    test('returns true when user exists', () async {
      const user = UserEntity(id: 'u1', email: 'a@b.c');
      when(mockRepo.authStateChanges())
          .thenAnswer((_) => Stream.value(user));

      container.dispose();
      container = _makeContainer(mockRepo, programCache: mockProgramCache);

      container.listen(authViewModelProvider, (_, __) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(isAuthenticatedProvider), true);
    });

    test('returns false when no user', () async {
      when(mockRepo.authStateChanges())
          .thenAnswer((_) => Stream.value(null));

      container.dispose();
      container = _makeContainer(mockRepo, programCache: mockProgramCache);

      container.listen(authViewModelProvider, (_, __) {}, fireImmediately: true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(isAuthenticatedProvider), false);
    });
  });
}
