import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:workout_tracker/core/errors/failure.dart';
import 'package:workout_tracker/domain/entities/exercise_library_entity.dart';
import 'package:workout_tracker/domain/repositories/i_workout_repository.dart';
import 'package:workout_tracker/presentation/viewmodels/exercise_library_viewmodel.dart';
import 'package:workout_tracker/presentation/viewmodels/program_viewmodel.dart';

@GenerateNiceMocks([MockSpec<IWorkoutRepository>()])
import 'exercise_library_viewmodel_test.mocks.dart';

ExerciseLibraryEntity _makeExercise(String id, String name) =>
    ExerciseLibraryEntity(
      id: id,
      name: name,
      muscleGroup: 'Legs',
      createdAt: DateTime(2026, 5, 1),
    );

ProviderContainer _makeContainer(IWorkoutRepository repo) {
  return ProviderContainer(
    overrides: [
      workoutRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

void main() {
  late MockIWorkoutRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockIWorkoutRepository();
    container = _makeContainer(mockRepo);
  });

  tearDown(() {
    container.dispose();
  });

  group('ExerciseLibraryState.filterByMuscleGroup', () {
    test('returns all exercises when muscleGroup is null', () {
      final state = ExerciseLibraryState(exercises: [
        _makeExercise('1', 'Squat'),
        _makeExercise('2', 'Bench'),
      ]);
      expect(state.filterByMuscleGroup(null), hasLength(2));
    });

    test('returns all exercises when muscleGroup is empty', () {
      final state = ExerciseLibraryState(exercises: [
        _makeExercise('1', 'Squat'),
      ]);
      expect(state.filterByMuscleGroup(''), hasLength(1));
    });

    test('filters by muscleGroup', () {
      final state = ExerciseLibraryState(exercises: [
        ExerciseLibraryEntity(
            id: '1', name: 'Squat', muscleGroup: 'Legs', createdAt: DateTime(2026, 5, 1)),
        ExerciseLibraryEntity(
            id: '2', name: 'Bench', muscleGroup: 'Chest', createdAt: DateTime(2026, 5, 1)),
        ExerciseLibraryEntity(
            id: '3', name: 'Lunge', muscleGroup: 'Legs', createdAt: DateTime(2026, 5, 1)),
      ]);
      final result = state.filterByMuscleGroup('Legs');
      expect(result, hasLength(2));
      expect(result.every((e) => e.muscleGroup == 'Legs'), true);
    });
  });

  group('ExerciseLibraryState.search', () {
    test('returns all when query is empty', () {
      final state = ExerciseLibraryState(exercises: [
        _makeExercise('1', 'Squat'),
        _makeExercise('2', 'Bench'),
      ]);
      expect(state.search(''), hasLength(2));
    });

    test('filters case-insensitively by name', () {
      final state = ExerciseLibraryState(exercises: [
        _makeExercise('1', 'Squat'),
        _makeExercise('2', 'Bench Press'),
        _makeExercise('3', 'Front Squat'),
      ]);
      final result = state.search('squat');
      expect(result, hasLength(2));
      expect(result.map((e) => e.name).toList(),
          containsAll(['Squat', 'Front Squat']));
    });
  });

  group('ExerciseLibraryViewModel.loadExercises', () {
    test('sets exercises on success', () async {
      when(mockRepo.getExerciseLibrary()).thenAnswer((_) async => [
            _makeExercise('1', 'Squat'),
            _makeExercise('2', 'Bench'),
          ]);

      final notifier =
          container.read(exerciseLibraryViewModelProvider.notifier);
      await notifier.loadExercises();

      final state = container.read(exerciseLibraryViewModelProvider);
      expect(state.exercises, hasLength(2));
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
    });

    test('sets errorMessage on ServerFailure', () async {
      when(mockRepo.getExerciseLibrary())
          .thenThrow(const ServerFailure(message: 'network error'));

      final notifier =
          container.read(exerciseLibraryViewModelProvider.notifier);
      await notifier.loadExercises();

      final state = container.read(exerciseLibraryViewModelProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, 'network error');
      expect(state.exercises, isEmpty);
    });

    test('sets errorMessage on unexpected exception', () async {
      when(mockRepo.getExerciseLibrary()).thenThrow(Exception('boom'));

      final notifier =
          container.read(exerciseLibraryViewModelProvider.notifier);
      await notifier.loadExercises();

      final state = container.read(exerciseLibraryViewModelProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNotNull);
    });
  });

  group('ExerciseLibraryViewModel.createExercise', () {
    test('calls repo and reloads on success', () async {
      when(mockRepo.createLibraryExercise(any))
          .thenAnswer((_) async => _makeExercise('new', 'OHP'));
      when(mockRepo.getExerciseLibrary())
          .thenAnswer((_) async => [_makeExercise('new', 'OHP')]);

      final notifier =
          container.read(exerciseLibraryViewModelProvider.notifier);
      await notifier.createExercise(name: 'OHP', muscleGroup: 'Shoulders');

      verify(mockRepo.createLibraryExercise(any)).called(1);
      final state = container.read(exerciseLibraryViewModelProvider);
      expect(state.exercises, hasLength(1));
    });

    test('sets errorMessage and rethrows on Failure', () async {
      when(mockRepo.createLibraryExercise(any))
          .thenThrow(const ServerFailure(message: 'create failed'));

      final notifier =
          container.read(exerciseLibraryViewModelProvider.notifier);

      expect(
        () => notifier.createExercise(name: 'OHP', muscleGroup: 'Shoulders'),
        throwsA(isA<ServerFailure>()),
      );
      await Future.delayed(Duration.zero);
    });
  });

  group('ExerciseLibraryViewModel.deleteExercise', () {
    test('calls repo and reloads on success', () async {
      when(mockRepo.deleteLibraryExercise('ex1')).thenAnswer((_) async {});
      when(mockRepo.getExerciseLibrary()).thenAnswer((_) async => []);

      final notifier =
          container.read(exerciseLibraryViewModelProvider.notifier);
      await notifier.deleteExercise('ex1');

      verify(mockRepo.deleteLibraryExercise('ex1')).called(1);
    });
  });
}
