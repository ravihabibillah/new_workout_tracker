import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/program_entity.dart';
import '../../domain/entities/exercise_entity.dart';
import '../../domain/repositories/i_workout_repository.dart';
import '../../domain/usecases/create_program_usecase.dart';
import '../../domain/usecases/get_programs_usecase.dart';
import '../../domain/usecases/update_program_usecase.dart';
import '../../domain/usecases/delete_program_usecase.dart';
import '../../data/repositories/workout_repository_impl.dart';
import '../../data/datasources/remote/firebase_workout_datasource.dart';
import '../../data/datasources/local/exercise_library_cache.dart';
import '../../data/datasources/local/program_cache.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_viewmodel.dart';

part 'program_viewmodel.g.dart';

/// Provider for the local Hive cache. Overridden in `main()` after Hive is
/// initialized so the rest of the app can read it synchronously.
@Riverpod(keepAlive: true)
ExerciseLibraryCache exerciseLibraryCache(ExerciseLibraryCacheRef ref) {
  throw UnimplementedError(
    'exerciseLibraryCacheProvider must be overridden in main()',
  );
}

/// Provider for the local Hive program cache. Overridden in `main()`.
@Riverpod(keepAlive: true)
ProgramCache programCache(ProgramCacheRef ref) {
  throw UnimplementedError(
    'programCacheProvider must be overridden in main()',
  );
}

/// Workout repository provider
@riverpod
IWorkoutRepository workoutRepository(WorkoutRepositoryRef ref) {
  return WorkoutRepositoryImpl(
    dataSource: FirebaseWorkoutDataSource(
      firestore: FirebaseFirestore.instance,
      firebaseAuth: FirebaseAuth.instance,
      libraryCache: ref.watch(exerciseLibraryCacheProvider),
      programCache: ref.watch(programCacheProvider),
    ),
  );
}

/// Program state
class ProgramState {
  final List<ProgramEntity> programs;
  final bool isLoading;
  final String? errorMessage;

  const ProgramState({
    this.programs = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ProgramState copyWith({
    List<ProgramEntity>? programs,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProgramState(
      programs: programs ?? this.programs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Program view model
@riverpod
class ProgramViewModel extends _$ProgramViewModel {
  @override
  ProgramState build() {
    final authState = ref.watch(authViewModelProvider);
    if (authState.hasValue && authState.value != null) {
      Future.microtask(loadPrograms);
    }
    return const ProgramState(isLoading: true);
  }

  /// Load all programs
  Future<void> loadPrograms() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final useCase = GetProgramsUseCase(repository);
      final programs = await useCase();
      state = state.copyWith(programs: programs, isLoading: false);
    } on Failure catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load programs: $e',
      );
    }
  }

  /// Create new program
  Future<void> createProgram({
    required String name,
    String? description,
    required List<ExerciseEntity> exercises,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final useCase = CreateProgramUseCase(repository);
      
      final program = ProgramEntity(
        id: '',
        userId: '',
        name: name,
        description: description,
        exercises: exercises,
        createdAt: DateTime.now(),
      );

      await useCase(program);
      await loadPrograms();
    } on Failure catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create program: $e',
      );
      rethrow;
    }
  }

  /// Update existing program
  Future<void> updateProgram(ProgramEntity program) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final useCase = UpdateProgramUseCase(repository);
      
      final updated = program.copyWith(updatedAt: DateTime.now());
      await useCase(updated);
      await loadPrograms();
    } on Failure catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update program: $e',
      );
      rethrow;
    }
  }

  /// Delete program
  Future<void> deleteProgram(String programId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final useCase = DeleteProgramUseCase(repository);
      
      await useCase(programId);
      await loadPrograms();
    } on Failure catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete program: $e',
      );
      rethrow;
    }
  }

  /// Get program by ID
  ProgramEntity? getProgramById(String programId) {
    return state.programs.firstWhere(
      (p) => p.id == programId,
      orElse: () => throw Exception('Program not found'),
    );
  }
}

/// Single program provider
@riverpod
Future<ProgramEntity?> programById(ProgramByIdRef ref, String programId) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return await repository.getProgramById(programId);
}
