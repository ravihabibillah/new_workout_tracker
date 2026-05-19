import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:workout_tracker/core/errors/failure.dart';
import 'package:workout_tracker/domain/entities/exercise_log_entity.dart';
import 'package:workout_tracker/domain/entities/set_log_entity.dart';
import 'package:workout_tracker/domain/entities/workout_session_entity.dart';
import 'package:workout_tracker/domain/repositories/i_workout_repository.dart';
import 'package:workout_tracker/presentation/viewmodels/program_viewmodel.dart';
import 'package:workout_tracker/presentation/viewmodels/workout_viewmodel.dart';

@GenerateNiceMocks([MockSpec<IWorkoutRepository>()])
import 'workout_viewmodel_test.mocks.dart';

WorkoutSessionEntity _session({
  String id = 's1',
  List<ExerciseLogEntity> logs = const [],
}) =>
    WorkoutSessionEntity(
      id: id,
      userId: 'u1',
      programId: 'p1',
      programName: 'Push Day',
      startTime: DateTime(2026, 5, 1, 9, 0),
      exerciseLogs: logs,
    );

ProviderContainer _makeContainer(IWorkoutRepository repo) {
  return ProviderContainer(
    overrides: [
      workoutRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

/// Reads the viewmodel (triggering build/_loadActiveSession) and waits for
/// the async work to settle.
Future<void> _initVm(ProviderContainer container) async {
  container.listen(workoutViewModelProvider, (_, __) {}, fireImmediately: true);
  // Drain microtasks + event queue several times to let the awaited mock
  // Future and the subsequent state update propagate.
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late MockIWorkoutRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockIWorkoutRepository();
    when(mockRepo.getActiveWorkoutSession()).thenAnswer((_) async => null);
    container = _makeContainer(mockRepo);
  });

  tearDown(() {
    container.dispose();
  });

  group('WorkoutState.copyWith', () {
    test('preserves activeSession when not specified (sentinel pattern)', () {
      final session = _session();
      final state = WorkoutState(activeSession: session);
      final updated = state.copyWith(isLoading: true);
      expect(updated.activeSession, session);
    });

    test('clears activeSession when explicitly set to null', () {
      final session = _session();
      final state = WorkoutState(activeSession: session);
      final updated = state.copyWith(activeSession: null);
      expect(updated.activeSession, isNull);
    });
  });

  group('WorkoutViewModel initial load', () {
    test('loads active session on build', () async {
      final session = _session();
      when(mockRepo.getActiveWorkoutSession())
          .thenAnswer((_) async => session);

      await _initVm(container);

      final state = container.read(workoutViewModelProvider);
      expect(state.activeSession, session);
      expect(state.isLoading, false);
    });

    test('handles error during initial load', () async {
      when(mockRepo.getActiveWorkoutSession())
          .thenAnswer((_) async => throw Exception('boom'));

      await _initVm(container);

      final state = container.read(workoutViewModelProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNotNull);
    });
  });

  group('WorkoutViewModel.startWorkout', () {
    test('sets activeSession on success', () async {
      final session = _session();
      when(mockRepo.startWorkoutSession(
        programId: 'p1',
        programName: 'Push',
        useRestTimer: false,
        restTimerDuration: 90,
      )).thenAnswer((_) async => session);

      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.startWorkout('p1', 'Push');

      final state = container.read(workoutViewModelProvider);
      expect(state.activeSession, session);
      expect(state.isLoading, false);
    });

    test('rethrows Failure and sets errorMessage', () async {
      when(mockRepo.startWorkoutSession(
        programId: anyNamed('programId'),
        programName: anyNamed('programName'),
        useRestTimer: anyNamed('useRestTimer'),
        restTimerDuration: anyNamed('restTimerDuration'),
      )).thenThrow(const ServerFailure(message: 'start failed'));

      final notifier = container.read(workoutViewModelProvider.notifier);

      await expectLater(
        notifier.startWorkout('p1', 'Push'),
        throwsA(isA<ServerFailure>()),
      );

      final state = container.read(workoutViewModelProvider);
      expect(state.errorMessage, 'start failed');
      expect(state.isLoading, false);
    });
  });

  group('WorkoutViewModel.addExerciseLog', () {
    test('does nothing when no active session', () async {
      await _initVm(container);
      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.addExerciseLog('ex1', 'Squat', 'Legs');

      verifyNever(mockRepo.updateWorkoutSession(any));
    });

    test('appends a new ExerciseLogEntity to active session', () async {
      final session = _session();
      when(mockRepo.getActiveWorkoutSession())
          .thenAnswer((_) async => session);
      when(mockRepo.updateWorkoutSession(any))
          .thenAnswer((_) async => session);

      await _initVm(container);

      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.addExerciseLog('ex1', 'Squat', 'Legs');

      final state = container.read(workoutViewModelProvider);
      expect(state.activeSession?.exerciseLogs, hasLength(1));
      expect(state.activeSession?.exerciseLogs.first.exerciseId, 'ex1');
      expect(state.activeSession?.exerciseLogs.first.exerciseName, 'Squat');
    });
  });

  group('WorkoutViewModel.addSet', () {
    test('appends a new set with incremented setNumber', () async {
      final session = _session(logs: const [
        ExerciseLogEntity(
          exerciseId: 'ex1',
          exerciseName: 'Squat',
          muscleGroup: 'Legs',
          sets: [
            SetLogEntity(setNumber: 1, weight: 50, reps: 10, unit: 'kg'),
          ],
        ),
      ]);
      when(mockRepo.getActiveWorkoutSession())
          .thenAnswer((_) async => session);
      when(mockRepo.updateWorkoutSession(any))
          .thenAnswer((_) async => session);

      await _initVm(container);

      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.addSet('ex1');

      final state = container.read(workoutViewModelProvider);
      final sets = state.activeSession!.exerciseLogs.first.sets;
      expect(sets, hasLength(2));
      expect(sets[1].setNumber, 2);
      // Inherits weight/reps from previous set when not provided.
      expect(sets[1].weight, 50);
      expect(sets[1].reps, 10);
    });

    test('does nothing when exerciseId not found', () async {
      final session = _session();
      when(mockRepo.getActiveWorkoutSession())
          .thenAnswer((_) async => session);

      await _initVm(container);

      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.addSet('missing');

      verifyNever(mockRepo.updateWorkoutSession(any));
    });
  });

  group('WorkoutViewModel.completeSet / uncompleteSet', () {
    final session = _session(logs: const [
      ExerciseLogEntity(
        exerciseId: 'ex1',
        exerciseName: 'Squat',
        muscleGroup: 'Legs',
        sets: [
          SetLogEntity(setNumber: 1, weight: 50, reps: 10, unit: 'kg'),
        ],
      ),
    ]);

    test('completeSet marks set as completed', () async {
      when(mockRepo.getActiveWorkoutSession())
          .thenAnswer((_) async => session);
      when(mockRepo.updateWorkoutSession(any))
          .thenAnswer((_) async => session);

      await _initVm(container);

      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.completeSet('ex1', 0);

      final state = container.read(workoutViewModelProvider);
      final set = state.activeSession!.exerciseLogs.first.sets[0];
      expect(set.isCompleted, true);
      expect(set.completedAt, isNotNull);
    });

    test('uncompleteSet marks set as not completed', () async {
      final completedSession = _session(logs: const [
        ExerciseLogEntity(
          exerciseId: 'ex1',
          exerciseName: 'Squat',
          muscleGroup: 'Legs',
          sets: [
            SetLogEntity(setNumber: 1, weight: 50, reps: 10, unit: 'kg', isCompleted: true),
          ],
        ),
      ]);
      when(mockRepo.getActiveWorkoutSession())
          .thenAnswer((_) async => completedSession);
      when(mockRepo.updateWorkoutSession(any))
          .thenAnswer((_) async => completedSession);

      await _initVm(container);

      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.uncompleteSet('ex1', 0);

      final state = container.read(workoutViewModelProvider);
      expect(state.activeSession!.exerciseLogs.first.sets[0].isCompleted, false);
    });

    test('completeSet does nothing when setIndex is out of bounds', () async {
      when(mockRepo.getActiveWorkoutSession())
          .thenAnswer((_) async => session);

      await _initVm(container);

      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.completeSet('ex1', 99);

      verifyNever(mockRepo.updateWorkoutSession(any));
    });
  });

  group('WorkoutViewModel.deleteSet', () {
    test('removes set and renumbers remaining sets', () async {
      final session = _session(logs: const [
        ExerciseLogEntity(
          exerciseId: 'ex1',
          exerciseName: 'Squat',
          muscleGroup: 'Legs',
          sets: [
            SetLogEntity(setNumber: 1, weight: 50, reps: 10, unit: 'kg'),
            SetLogEntity(setNumber: 2, weight: 60, reps: 8, unit: 'kg'),
            SetLogEntity(setNumber: 3, weight: 70, reps: 6, unit: 'kg'),
          ],
        ),
      ]);
      when(mockRepo.getActiveWorkoutSession())
          .thenAnswer((_) async => session);
      when(mockRepo.updateWorkoutSession(any))
          .thenAnswer((_) async => session);

      await _initVm(container);

      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.deleteSet('ex1', 1);

      final state = container.read(workoutViewModelProvider);
      final sets = state.activeSession!.exerciseLogs.first.sets;
      expect(sets, hasLength(2));
      expect(sets[0].setNumber, 1);
      expect(sets[0].weight, 50);
      expect(sets[1].setNumber, 2);
      expect(sets[1].weight, 70);
    });
  });

  group('WorkoutViewModel rest timer', () {
    test('skipRestTimer resets timer state', () {
      final notifier = container.read(workoutViewModelProvider.notifier);
      notifier.startRestTimer(60);
      notifier.skipRestTimer();

      final state = container.read(workoutViewModelProvider);
      expect(state.restTimerSeconds, 0);
      expect(state.isRestTimerActive, false);
    });

    test('extendRestTimer adds to remaining seconds', () {
      final notifier = container.read(workoutViewModelProvider.notifier);
      notifier.startRestTimer(30);
      notifier.extendRestTimer(15);

      final state = container.read(workoutViewModelProvider);
      expect(state.restTimerSeconds, 45);
    });
  });

  group('WorkoutViewModel.finishWorkout', () {
    test('clears activeSession on success', () async {
      final session = _session();
      when(mockRepo.getActiveWorkoutSession())
          .thenAnswer((_) async => session);
      when(mockRepo.completeWorkoutSession('s1'))
          .thenAnswer((_) async => session);

      await _initVm(container);

      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.finishWorkout();

      final state = container.read(workoutViewModelProvider);
      expect(state.activeSession, isNull);
      expect(state.isLoading, false);
    });

    test('does nothing when no active session', () async {
      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.finishWorkout();

      verifyNever(mockRepo.completeWorkoutSession(any));
    });
  });

  group('WorkoutViewModel.cancelWorkout', () {
    test('clears activeSession on success', () async {
      final session = _session();
      when(mockRepo.getActiveWorkoutSession())
          .thenAnswer((_) async => session);
      when(mockRepo.cancelWorkoutSession('s1')).thenAnswer((_) async {});

      await _initVm(container);

      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.cancelWorkout();

      final state = container.read(workoutViewModelProvider);
      expect(state.activeSession, isNull);
    });

    test('sets errorMessage when cancel fails', () async {
      final session = _session();
      when(mockRepo.getActiveWorkoutSession())
          .thenAnswer((_) async => session);
      when(mockRepo.cancelWorkoutSession('s1'))
          .thenThrow(Exception('cancel failed'));

      await _initVm(container);

      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.cancelWorkout();

      final state = container.read(workoutViewModelProvider);
      expect(state.errorMessage, isNotNull);
      // activeSession not cleared because cancel failed
      expect(state.activeSession, session);
    });
  });
}
