import '../entities/program_entity.dart';
import '../entities/workout_session_entity.dart';
import '../entities/exercise_log_entity.dart';
import '../entities/exercise_library_entity.dart';

/// Workout repository interface
abstract class IWorkoutRepository {
  // ========== Exercise Library Operations ==========

  /// Get all exercises in the user's library
  Future<List<ExerciseLibraryEntity>> getExerciseLibrary();

  /// Get exercise from library by ID
  Future<ExerciseLibraryEntity?> getExerciseLibraryById(String exerciseId);

  /// Add a new exercise to the library
  Future<ExerciseLibraryEntity> createLibraryExercise(
    ExerciseLibraryEntity exercise,
  );

  /// Update an exercise in the library
  Future<ExerciseLibraryEntity> updateLibraryExercise(
    ExerciseLibraryEntity exercise,
  );

  /// Delete an exercise from the library
  Future<void> deleteLibraryExercise(String exerciseId);

  /// Stream of exercise library
  Stream<List<ExerciseLibraryEntity>> watchExerciseLibrary();

  // ========== Program Operations ==========
  
  /// Get all programs for current user
  Future<List<ProgramEntity>> getPrograms();

  /// Get program by ID
  Future<ProgramEntity?> getProgramById(String programId);

  /// Create new program
  Future<ProgramEntity> createProgram(ProgramEntity program);

  /// Update existing program
  Future<ProgramEntity> updateProgram(ProgramEntity program);

  /// Delete program
  Future<void> deleteProgram(String programId);

  /// Stream of programs
  Stream<List<ProgramEntity>> watchPrograms();

  // ========== Workout Session Operations ==========

  /// Get active workout session (if any)
  Future<WorkoutSessionEntity?> getActiveWorkoutSession();

  /// Start new workout session
  Future<WorkoutSessionEntity> startWorkoutSession({
    required String programId,
    required String programName,
    bool useRestTimer = false,
    int restTimerDuration = 90,
  });

  /// Start a quick workout session (without a program)
  Future<WorkoutSessionEntity> startQuickWorkoutSession({
    String programName = 'Quick Workout',
    bool useRestTimer = false,
    int restTimerDuration = 90,
  });

  /// Update workout session
  Future<WorkoutSessionEntity> updateWorkoutSession(
    WorkoutSessionEntity session,
  );

  /// Complete workout session
  Future<WorkoutSessionEntity> completeWorkoutSession(String sessionId);

  /// Cancel workout session
  Future<void> cancelWorkoutSession(String sessionId);

  /// Get workout session by ID
  Future<WorkoutSessionEntity?> getWorkoutSessionById(String sessionId);

  // ========== Workout History Operations ==========

  /// Get workout history for user
  Future<List<WorkoutSessionEntity>> getWorkoutHistory({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get workout history for specific program
  Future<List<WorkoutSessionEntity>> getWorkoutHistoryByProgram(
    String programId, {
    int? limit,
  });

  /// Get workout history for specific exercise
  Future<List<ExerciseLogEntity>> getExerciseHistory(
    String exerciseName, {
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  });

  // ========== Progress Operations ==========

  /// Get all unique exercises from workout history
  Future<List<String>> getAllExerciseNames();

  /// Get personal records for an exercise
  Future<Map<String, dynamic>> getExercisePersonalRecords(String exerciseName);

  /// Get exercise progress data for charts
  Future<List<Map<String, dynamic>>> getExerciseProgressData(
    String exerciseName, {
    DateTime? startDate,
    DateTime? endDate,
  });

  // ========== Statistics Operations ==========

  /// Get total workout count
  Future<int> getTotalWorkoutCount();

  /// Get total volume lifted
  Future<double> getTotalVolume();

  /// Get workout streak
  Future<int> getCurrentStreak();
}
