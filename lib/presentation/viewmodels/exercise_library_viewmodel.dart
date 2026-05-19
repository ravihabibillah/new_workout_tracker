import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/exercise_library_entity.dart';
import 'program_viewmodel.dart';

part 'exercise_library_viewmodel.g.dart';

class ExerciseLibraryState {
  final List<ExerciseLibraryEntity> exercises;
  final bool isLoading;
  final String? errorMessage;

  const ExerciseLibraryState({
    this.exercises = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ExerciseLibraryState copyWith({
    List<ExerciseLibraryEntity>? exercises,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ExerciseLibraryState(
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  List<ExerciseLibraryEntity> filterByMuscleGroup(String? muscleGroup) {
    if (muscleGroup == null || muscleGroup.isEmpty) return exercises;
    return exercises.where((e) => e.muscleGroup == muscleGroup).toList();
  }

  List<ExerciseLibraryEntity> search(String query) {
    if (query.isEmpty) return exercises;
    final lowerQuery = query.toLowerCase();
    return exercises
        .where((e) => e.name.toLowerCase().contains(lowerQuery))
        .toList();
  }
}

@riverpod
class ExerciseLibraryViewModel extends _$ExerciseLibraryViewModel {
  @override
  ExerciseLibraryState build() {
    Future.microtask(loadExercises);
    return const ExerciseLibraryState(isLoading: true);
  }

  Future<void> loadExercises() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final exercises = await repository.getExerciseLibrary();
      state = state.copyWith(exercises: exercises, isLoading: false);
    } on Failure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load exercises: $e',
      );
    }
  }

  Future<void> createExercise({
    required String name,
    required String muscleGroup,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final exercise = ExerciseLibraryEntity(
        id: '',
        name: name,
        muscleGroup: muscleGroup,
        description: description,
        createdAt: DateTime.now(),
      );
      await repository.createLibraryExercise(exercise);
      await loadExercises();
    } on Failure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create exercise: $e',
      );
      rethrow;
    }
  }

  Future<void> updateExercise(ExerciseLibraryEntity exercise) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final updated = exercise.copyWith(updatedAt: DateTime.now());
      await repository.updateLibraryExercise(updated);
      await loadExercises();
    } on Failure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update exercise: $e',
      );
      rethrow;
    }
  }

  Future<void> deleteExercise(String exerciseId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(workoutRepositoryProvider);
      await repository.deleteLibraryExercise(exerciseId);
      await loadExercises();
    } on Failure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete exercise: $e',
      );
      rethrow;
    }
  }
}
