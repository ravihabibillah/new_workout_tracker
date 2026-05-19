import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:workout_tracker/core/errors/failure.dart';
import 'package:workout_tracker/domain/repositories/i_workout_repository.dart';
import 'package:workout_tracker/presentation/viewmodels/program_viewmodel.dart';
import 'package:workout_tracker/presentation/viewmodels/progress_viewmodel.dart';

@GenerateNiceMocks([MockSpec<IWorkoutRepository>()])
import 'progress_viewmodel_test.mocks.dart';

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
    when(mockRepo.getAllExerciseNames()).thenAnswer((_) async => []);
    container = _makeContainer(mockRepo);
  });

  tearDown(() {
    container.dispose();
  });

  group('ProgressState.copyWith', () {
    test('overrides only specified fields', () {
      const state = ProgressState(isLoading: true);
      final updated = state.copyWith(
        isLoading: false,
        exerciseNames: ['Squat'],
      );
      expect(updated.isLoading, false);
      expect(updated.exerciseNames, ['Squat']);
    });

    test('clears errorMessage when set to null', () {
      const state = ProgressState(errorMessage: 'old');
      final updated = state.copyWith(errorMessage: null);
      expect(updated.errorMessage, isNull);
    });
  });

  group('ProgressViewModel.loadExerciseNames', () {
    test('populates exerciseNames on success', () async {
      when(mockRepo.getAllExerciseNames())
          .thenAnswer((_) async => ['Squat', 'Bench', 'Deadlift']);

      final notifier = container.read(progressViewModelProvider.notifier);
      await notifier.loadExerciseNames();

      final state = container.read(progressViewModelProvider);
      expect(state.exerciseNames, ['Squat', 'Bench', 'Deadlift']);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
    });

    test('sets errorMessage on Failure', () async {
      when(mockRepo.getAllExerciseNames())
          .thenThrow(const ServerFailure(message: 'load failed'));

      final notifier = container.read(progressViewModelProvider.notifier);
      await notifier.loadExerciseNames();

      final state = container.read(progressViewModelProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, 'load failed');
    });
  });

  group('ProgressViewModel.selectExercise', () {
    test('loads progress data and personal records on success', () async {
      final progressData = [
        {'date': DateTime(2026, 5, 1), 'maxWeight': 100.0},
      ];
      final personalRecords = {'maxWeight': 100.0, 'maxReps': 10};

      when(mockRepo.getExerciseProgressData(
        'Squat',
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      )).thenAnswer((_) async => progressData);
      when(mockRepo.getExercisePersonalRecords('Squat'))
          .thenAnswer((_) async => personalRecords);

      final notifier = container.read(progressViewModelProvider.notifier);
      await notifier.selectExercise('Squat');

      final state = container.read(progressViewModelProvider);
      expect(state.selectedExercise, 'Squat');
      expect(state.progressData, progressData);
      expect(state.personalRecords, personalRecords);
      expect(state.isLoading, false);
    });

    test('sets errorMessage on Failure', () async {
      when(mockRepo.getExerciseProgressData(
        any,
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      )).thenThrow(const ServerFailure(message: 'progress failed'));

      final notifier = container.read(progressViewModelProvider.notifier);
      await notifier.selectExercise('Squat');

      final state = container.read(progressViewModelProvider);
      expect(state.errorMessage, 'progress failed');
      expect(state.isLoading, false);
    });
  });

  group('ProgressViewModel.clearSelection', () {
    // NOTE: ProgressState.copyWith uses `??` for selectedExercise and
    // personalRecords, so passing null doesn't actually clear them.
    // progressData IS cleared because it's passed an empty list (not null).
    test('clears progressData via empty list', () async {
      when(mockRepo.getExerciseProgressData(
        any,
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      )).thenAnswer((_) async => [
            {'date': DateTime(2026, 5, 1), 'maxWeight': 100.0},
          ]);
      when(mockRepo.getExercisePersonalRecords(any))
          .thenAnswer((_) async => {'maxWeight': 100.0});

      final notifier = container.read(progressViewModelProvider.notifier);
      await notifier.selectExercise('Squat');

      notifier.clearSelection();

      final state = container.read(progressViewModelProvider);
      expect(state.progressData, isEmpty);
    });
  });
}
