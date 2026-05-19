import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:workout_tracker/core/errors/failure.dart';
import 'package:workout_tracker/domain/entities/exercise_entity.dart';
import 'package:workout_tracker/domain/entities/program_entity.dart';
import 'package:workout_tracker/domain/repositories/i_workout_repository.dart';
import 'package:workout_tracker/presentation/viewmodels/program_viewmodel.dart';
import 'package:workout_tracker/data/datasources/local/exercise_library_cache.dart';
import 'package:workout_tracker/data/datasources/local/program_cache.dart';

@GenerateNiceMocks([
  MockSpec<IWorkoutRepository>(),
  MockSpec<ExerciseLibraryCache>(),
  MockSpec<ProgramCache>(),
])
import 'program_viewmodel_test.mocks.dart';

ProgramEntity _makeProgram(String id, String name) => ProgramEntity(
      id: id,
      userId: 'u1',
      name: name,
      exercises: const [
        ExerciseEntity(id: 'e1', name: 'Squat', muscleGroup: 'Legs', order: 0),
      ],
      createdAt: DateTime(2026, 5, 1),
    );

ProviderContainer _makeContainer(
  IWorkoutRepository repo, {
  ExerciseLibraryCache? libraryCache,
  ProgramCache? programCache,
}) {
  return ProviderContainer(
    overrides: [
      workoutRepositoryProvider.overrideWithValue(repo),
      if (libraryCache != null)
        exerciseLibraryCacheProvider.overrideWithValue(libraryCache),
      if (programCache != null)
        programCacheProvider.overrideWithValue(programCache),
    ],
  );
}

void main() {
  late MockIWorkoutRepository mockRepo;
  late MockExerciseLibraryCache mockLibraryCache;
  late MockProgramCache mockProgramCache;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockIWorkoutRepository();
    mockLibraryCache = MockExerciseLibraryCache();
    mockProgramCache = MockProgramCache();
    container = _makeContainer(
      mockRepo,
      libraryCache: mockLibraryCache,
      programCache: mockProgramCache,
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ProgramState.copyWith', () {
    test('overrides only specified fields', () {
      const state = ProgramState(isLoading: true);
      final updated = state.copyWith(isLoading: false, errorMessage: 'err');
      expect(updated.isLoading, false);
      expect(updated.errorMessage, 'err');
      expect(updated.programs, isEmpty);
    });

    test('clears errorMessage when set to null via copyWith', () {
      const state = ProgramState(errorMessage: 'old error');
      final updated = state.copyWith(errorMessage: null);
      expect(updated.errorMessage, isNull);
    });
  });

  group('ProgramViewModel.loadPrograms', () {
    test('sets programs on success', () async {
      when(mockRepo.getPrograms()).thenAnswer((_) async => [
            _makeProgram('p1', 'Push'),
            _makeProgram('p2', 'Pull'),
          ]);

      final notifier = container.read(programViewModelProvider.notifier);
      await notifier.loadPrograms();

      final state = container.read(programViewModelProvider);
      expect(state.programs, hasLength(2));
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
    });

    test('sets errorMessage on Failure', () async {
      when(mockRepo.getPrograms())
          .thenThrow(const ServerFailure(message: 'server down'));

      final notifier = container.read(programViewModelProvider.notifier);
      await notifier.loadPrograms();

      final state = container.read(programViewModelProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, 'server down');
    });

    test('sets errorMessage on unexpected exception', () async {
      when(mockRepo.getPrograms()).thenThrow(Exception('boom'));

      final notifier = container.read(programViewModelProvider.notifier);
      await notifier.loadPrograms();

      final state = container.read(programViewModelProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNotNull);
    });
  });

  group('ProgramViewModel.createProgram', () {
    test('calls repo and reloads on success', () async {
      when(mockRepo.createProgram(any))
          .thenAnswer((_) async => _makeProgram('p1', 'New'));
      when(mockRepo.getPrograms())
          .thenAnswer((_) async => [_makeProgram('p1', 'New')]);

      final notifier = container.read(programViewModelProvider.notifier);
      await notifier.createProgram(
        name: 'New',
        exercises: const [
          ExerciseEntity(id: 'e1', name: 'Squat', muscleGroup: 'Legs', order: 0),
        ],
      );

      verify(mockRepo.createProgram(any)).called(1);
      final state = container.read(programViewModelProvider);
      expect(state.programs, hasLength(1));
    });

    test('sets errorMessage and rethrows on Failure', () async {
      when(mockRepo.createProgram(any))
          .thenThrow(const ServerFailure(message: 'create failed'));

      final notifier = container.read(programViewModelProvider.notifier);

      expect(
        () => notifier.createProgram(name: 'X', exercises: const []),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('ProgramViewModel.updateProgram', () {
    test('calls repo and reloads on success', () async {
      final program = _makeProgram('p1', 'Updated');
      when(mockRepo.updateProgram(any)).thenAnswer((_) async => program);
      when(mockRepo.getPrograms()).thenAnswer((_) async => [program]);

      final notifier = container.read(programViewModelProvider.notifier);
      await notifier.updateProgram(program);

      verify(mockRepo.updateProgram(any)).called(1);
    });
  });

  group('ProgramViewModel.deleteProgram', () {
    test('calls repo and reloads on success', () async {
      when(mockRepo.deleteProgram('p1')).thenAnswer((_) async {});
      when(mockRepo.getPrograms()).thenAnswer((_) async => []);

      final notifier = container.read(programViewModelProvider.notifier);
      await notifier.deleteProgram('p1');

      verify(mockRepo.deleteProgram('p1')).called(1);
      final state = container.read(programViewModelProvider);
      expect(state.programs, isEmpty);
    });
  });

  group('ProgramViewModel.getProgramById', () {
    test('returns program from state when found', () async {
      when(mockRepo.getPrograms())
          .thenAnswer((_) async => [_makeProgram('p1', 'Push')]);

      final notifier = container.read(programViewModelProvider.notifier);
      await notifier.loadPrograms();

      final result = notifier.getProgramById('p1');
      expect(result?.name, 'Push');
    });

    test('throws when program not found', () async {
      when(mockRepo.getPrograms()).thenAnswer((_) async => []);

      final notifier = container.read(programViewModelProvider.notifier);
      await notifier.loadPrograms();

      expect(() => notifier.getProgramById('missing'), throwsException);
    });
  });
}
