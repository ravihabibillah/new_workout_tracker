import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/workout_session_entity.dart';
import '../../domain/entities/exercise_log_entity.dart';
import '../../domain/entities/set_log_entity.dart';
import '../../domain/usecases/start_workout_usecase.dart';
import '../../domain/usecases/complete_workout_usecase.dart';
import 'program_viewmodel.dart';

part 'workout_viewmodel.g.dart';

class WorkoutState {
  final WorkoutSessionEntity? activeSession;
  final bool isLoading;
  final String? errorMessage;
  final int? restTimerSeconds;
  final bool isRestTimerActive;

  const WorkoutState({
    this.activeSession,
    this.isLoading = false,
    this.errorMessage,
    this.restTimerSeconds,
    this.isRestTimerActive = false,
  });

  WorkoutState copyWith({
    Object? activeSession = _sentinel,
    bool? isLoading,
    String? errorMessage,
    int? restTimerSeconds,
    bool? isRestTimerActive,
  }) {
    return WorkoutState(
      activeSession: identical(activeSession, _sentinel)
          ? this.activeSession
          : activeSession as WorkoutSessionEntity?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      restTimerSeconds: restTimerSeconds ?? this.restTimerSeconds,
      isRestTimerActive: isRestTimerActive ?? this.isRestTimerActive,
    );
  }
}

const _sentinel = Object();

@riverpod
class WorkoutViewModel extends _$WorkoutViewModel {
  Timer? _restTimer;

  @override
  WorkoutState build() {
    ref.onDispose(() {
      _restTimer?.cancel();
    });
    _loadActiveSession();
    return const WorkoutState(isLoading: true);
  }

  Future<void> _loadActiveSession() async {
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final session = await repository.getActiveWorkoutSession();
      state = state.copyWith(activeSession: session, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load session');
    }
  }

  Future<void> startWorkout(String programId, String programName, {
    bool useRestTimer = false,
    int restTimerDuration = 90,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final useCase = StartWorkoutUseCase(repository);
      final session = await useCase(
        programId: programId,
        programName: programName,
        useRestTimer: useRestTimer,
        restTimerDuration: restTimerDuration,
      );
      state = state.copyWith(activeSession: session, isLoading: false);
    } on Failure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      rethrow;
    }
  }

  Future<void> addExerciseLog(String exerciseId, String exerciseName, String muscleGroup) async {
    final session = state.activeSession;
    if (session == null) return;

    final newLog = ExerciseLogEntity(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      muscleGroup: muscleGroup,
      sets: [],
    );

    final updatedLogs = [...session.exerciseLogs, newLog];
    final updatedSession = session.copyWith(exerciseLogs: updatedLogs);

    await _updateSession(updatedSession);
  }

  Future<void> addSet(String exerciseId, {double? weight, int? reps}) async {
    final session = state.activeSession;
    if (session == null) return;

    final exerciseIndex = session.exerciseLogs.indexWhere((log) => log.exerciseId == exerciseId);
    if (exerciseIndex == -1) return;

    final exercise = session.exerciseLogs[exerciseIndex];
    final setNumber = exercise.sets.length + 1;

    final newSet = SetLogEntity(
      setNumber: setNumber,
      weight: weight ?? (exercise.sets.isNotEmpty ? exercise.sets.last.weight : 0),
      reps: reps ?? (exercise.sets.isNotEmpty ? exercise.sets.last.reps : 0),
      unit: 'kg',
      isCompleted: false,
    );

    final updatedSets = [...exercise.sets, newSet];
    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedLogs = [...session.exerciseLogs];
    updatedLogs[exerciseIndex] = updatedExercise;

    final updatedSession = session.copyWith(exerciseLogs: updatedLogs);
    await _updateSession(updatedSession);
  }

  Future<void> updateSet(String exerciseId, int setIndex, {double? weight, int? reps}) async {
    final session = state.activeSession;
    if (session == null) return;

    final exerciseIndex = session.exerciseLogs.indexWhere((log) => log.exerciseId == exerciseId);
    if (exerciseIndex == -1) return;

    final exercise = session.exerciseLogs[exerciseIndex];
    if (setIndex >= exercise.sets.length) return;

    final updatedSet = exercise.sets[setIndex].copyWith(
      weight: weight,
      reps: reps,
    );

    final updatedSets = [...exercise.sets];
    updatedSets[setIndex] = updatedSet;
    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedLogs = [...session.exerciseLogs];
    updatedLogs[exerciseIndex] = updatedExercise;

    final updatedSession = session.copyWith(exerciseLogs: updatedLogs);
    await _updateSession(updatedSession);
  }

  Future<void> completeSet(String exerciseId, int setIndex) async {
    final session = state.activeSession;
    if (session == null) return;

    final exerciseIndex = session.exerciseLogs.indexWhere((log) => log.exerciseId == exerciseId);
    if (exerciseIndex == -1) return;

    final exercise = session.exerciseLogs[exerciseIndex];
    if (setIndex >= exercise.sets.length) return;

    final updatedSet = exercise.sets[setIndex].copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    final updatedSets = [...exercise.sets];
    updatedSets[setIndex] = updatedSet;
    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedLogs = [...session.exerciseLogs];
    updatedLogs[exerciseIndex] = updatedExercise;

    final updatedSession = session.copyWith(exerciseLogs: updatedLogs);
    await _updateSession(updatedSession);
  }

  Future<void> uncompleteSet(String exerciseId, int setIndex) async {
    final session = state.activeSession;
    if (session == null) return;

    final exerciseIndex = session.exerciseLogs.indexWhere((log) => log.exerciseId == exerciseId);
    if (exerciseIndex == -1) return;

    final exercise = session.exerciseLogs[exerciseIndex];
    if (setIndex >= exercise.sets.length) return;

    final updatedSet = exercise.sets[setIndex].copyWith(
      isCompleted: false,
    );

    final updatedSets = [...exercise.sets];
    updatedSets[setIndex] = updatedSet;
    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedLogs = [...session.exerciseLogs];
    updatedLogs[exerciseIndex] = updatedExercise;

    final updatedSession = session.copyWith(exerciseLogs: updatedLogs);
    await _updateSession(updatedSession);
  }

  Future<void> deleteSet(String exerciseId, int setIndex) async {
    final session = state.activeSession;
    if (session == null) return;

    final exerciseIndex = session.exerciseLogs.indexWhere((log) => log.exerciseId == exerciseId);
    if (exerciseIndex == -1) return;

    final exercise = session.exerciseLogs[exerciseIndex];
    if (setIndex >= exercise.sets.length) return;

    final updatedSets = [...exercise.sets]..removeAt(setIndex);
    for (int i = 0; i < updatedSets.length; i++) {
      updatedSets[i] = updatedSets[i].copyWith(setNumber: i + 1);
    }

    final updatedExercise = exercise.copyWith(sets: updatedSets);
    final updatedLogs = [...session.exerciseLogs];
    updatedLogs[exerciseIndex] = updatedExercise;

    final updatedSession = session.copyWith(exerciseLogs: updatedLogs);
    await _updateSession(updatedSession);
  }

  void startRestTimer(int seconds) {
    _restTimer?.cancel();
    state = state.copyWith(restTimerSeconds: seconds, isRestTimerActive: true);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state.restTimerSeconds ?? 0;
      if (current <= 1) {
        timer.cancel();
        state = state.copyWith(restTimerSeconds: 0, isRestTimerActive: false);
      } else {
        state = state.copyWith(restTimerSeconds: current - 1);
      }
    });
  }

  void skipRestTimer() {
    _restTimer?.cancel();
    state = state.copyWith(restTimerSeconds: 0, isRestTimerActive: false);
  }

  void extendRestTimer(int additionalSeconds) {
    final current = state.restTimerSeconds ?? 0;
    state = state.copyWith(restTimerSeconds: current + additionalSeconds);
  }

  Future<void> finishWorkout() async {
    final session = state.activeSession;
    if (session == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final useCase = CompleteWorkoutUseCase(repository);
      await useCase(session.id);
      state = state.copyWith(activeSession: null, isLoading: false);
    } on Failure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      rethrow;
    }
  }

  Future<void> cancelWorkout() async {
    final session = state.activeSession;
    if (session == null) return;

    try {
      final repository = ref.read(workoutRepositoryProvider);
      await repository.cancelWorkoutSession(session.id);
      state = state.copyWith(activeSession: null);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to cancel workout');
    }
  }

  Future<void> _updateSession(WorkoutSessionEntity session) async {
    try {
      final repository = ref.read(workoutRepositoryProvider);
      await repository.updateWorkoutSession(session);
      state = state.copyWith(activeSession: session);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update session');
    }
  }
}
