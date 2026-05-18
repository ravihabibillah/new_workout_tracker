import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/errors/failure.dart';
import '../../domain/usecases/get_exercise_progress_usecase.dart';
import 'program_viewmodel.dart';

part 'progress_viewmodel.g.dart';

class ProgressState {
  final List<String> exerciseNames;
  final String? selectedExercise;
  final List<Map<String, dynamic>> progressData;
  final Map<String, dynamic>? personalRecords;
  final bool isLoading;
  final String? errorMessage;

  const ProgressState({
    this.exerciseNames = const [],
    this.selectedExercise,
    this.progressData = const [],
    this.personalRecords,
    this.isLoading = false,
    this.errorMessage,
  });

  ProgressState copyWith({
    List<String>? exerciseNames,
    String? selectedExercise,
    List<Map<String, dynamic>>? progressData,
    Map<String, dynamic>? personalRecords,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProgressState(
      exerciseNames: exerciseNames ?? this.exerciseNames,
      selectedExercise: selectedExercise ?? this.selectedExercise,
      progressData: progressData ?? this.progressData,
      personalRecords: personalRecords ?? this.personalRecords,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

@riverpod
class ProgressViewModel extends _$ProgressViewModel {
  @override
  ProgressState build() {
    loadExerciseNames();
    return const ProgressState(isLoading: true);
  }

  Future<void> loadExerciseNames() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final names = await repository.getAllExerciseNames();
      state = state.copyWith(exerciseNames: names, isLoading: false);
    } on Failure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load exercises: $e',
      );
    }
  }

  Future<void> selectExercise(String exerciseName) async {
    state = state.copyWith(
      selectedExercise: exerciseName,
      isLoading: true,
      errorMessage: null,
    );

    try {
      final repository = ref.read(workoutRepositoryProvider);
      
      final progressUseCase = GetExerciseProgressUseCase(repository);
      final progressData = await progressUseCase(exerciseName);
      
      final personalRecords = await repository.getExercisePersonalRecords(exerciseName);

      state = state.copyWith(
        progressData: progressData,
        personalRecords: personalRecords,
        isLoading: false,
      );
    } on Failure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load progress: $e',
      );
    }
  }

  void clearSelection() {
    state = state.copyWith(
      selectedExercise: null,
      progressData: [],
      personalRecords: null,
    );
  }
}

@riverpod
Future<Map<String, dynamic>> exercisePersonalRecords(
  ExercisePersonalRecordsRef ref,
  String exerciseName,
) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return await repository.getExercisePersonalRecords(exerciseName);
}

@riverpod
Future<List<Map<String, dynamic>>> exerciseProgressData(
  ExerciseProgressDataRef ref,
  String exerciseName,
) async {
  final repository = ref.watch(workoutRepositoryProvider);
  final useCase = GetExerciseProgressUseCase(repository);
  return await useCase(exerciseName);
}
