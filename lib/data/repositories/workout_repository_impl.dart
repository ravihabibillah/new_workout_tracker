import '../../core/errors/exceptions.dart';
import '../../core/errors/failure.dart';
import '../../domain/entities/program_entity.dart';
import '../../domain/entities/workout_session_entity.dart';
import '../../domain/entities/exercise_log_entity.dart';
import '../../domain/repositories/i_workout_repository.dart';
import '../datasources/remote/firebase_workout_datasource.dart';
import '../models/program_model.dart';
import '../models/workout_session_model.dart';

/// Workout repository implementation
class WorkoutRepositoryImpl implements IWorkoutRepository {
  final FirebaseWorkoutDataSource _dataSource;

  WorkoutRepositoryImpl({required FirebaseWorkoutDataSource dataSource})
      : _dataSource = dataSource;

  // ========== Program Operations ==========

  @override
  Future<List<ProgramEntity>> getPrograms() async {
    try {
      final programs = await _dataSource.getPrograms();
      return programs.map((p) => p.toEntity()).toList();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get programs: $e');
    }
  }

  @override
  Future<ProgramEntity?> getProgramById(String programId) async {
    try {
      final program = await _dataSource.getProgramById(programId);
      return program?.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get program: $e');
    }
  }

  @override
  Future<ProgramEntity> createProgram(ProgramEntity program) async {
    try {
      final programModel = ProgramModel.fromEntity(program);
      final created = await _dataSource.createProgram(programModel);
      return created.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to create program: $e');
    }
  }

  @override
  Future<ProgramEntity> updateProgram(ProgramEntity program) async {
    try {
      final programModel = ProgramModel.fromEntity(program);
      final updated = await _dataSource.updateProgram(programModel);
      return updated.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to update program: $e');
    }
  }

  @override
  Future<void> deleteProgram(String programId) async {
    try {
      await _dataSource.deleteProgram(programId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to delete program: $e');
    }
  }

  @override
  Stream<List<ProgramEntity>> watchPrograms() {
    try {
      return _dataSource.watchPrograms().map(
            (programs) => programs.map((p) => p.toEntity()).toList(),
          );
    } catch (e) {
      throw ServerFailure(message: 'Failed to watch programs: $e');
    }
  }

  // ========== Workout Session Operations ==========

  @override
  Future<WorkoutSessionEntity?> getActiveWorkoutSession() async {
    try {
      final session = await _dataSource.getActiveWorkoutSession();
      return session?.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get active session: $e');
    }
  }

  @override
  Future<WorkoutSessionEntity> startWorkoutSession({
    required String programId,
    required String programName,
  }) async {
    try {
      final session = await _dataSource.startWorkoutSession(
        programId: programId,
        programName: programName,
      );
      return session.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to start session: $e');
    }
  }

  @override
  Future<WorkoutSessionEntity> updateWorkoutSession(
    WorkoutSessionEntity session,
  ) async {
    try {
      final sessionModel = WorkoutSessionModel.fromEntity(session);
      final updated = await _dataSource.updateWorkoutSession(sessionModel);
      return updated.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to update session: $e');
    }
  }

  @override
  Future<WorkoutSessionEntity> completeWorkoutSession(String sessionId) async {
    try {
      final session = await _dataSource.completeWorkoutSession(sessionId);
      return session.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to complete session: $e');
    }
  }

  @override
  Future<void> cancelWorkoutSession(String sessionId) async {
    try {
      await _dataSource.cancelWorkoutSession(sessionId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to cancel session: $e');
    }
  }

  @override
  Future<WorkoutSessionEntity?> getWorkoutSessionById(String sessionId) async {
    try {
      final session = await _dataSource.getWorkoutSessionById(sessionId);
      return session?.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get session: $e');
    }
  }

  // ========== Workout History Operations ==========

  @override
  Future<List<WorkoutSessionEntity>> getWorkoutHistory({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final sessions = await _dataSource.getWorkoutHistory(
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );
      return sessions.map((s) => s.toEntity()).toList();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get workout history: $e');
    }
  }

  @override
  Future<List<WorkoutSessionEntity>> getWorkoutHistoryByProgram(
    String programId, {
    int? limit,
  }) async {
    try {
      final allSessions = await _dataSource.getWorkoutHistory(limit: limit);
      final filtered = allSessions
          .where((s) => s.programId == programId)
          .map((s) => s.toEntity())
          .toList();
      return filtered;
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get program history: $e');
    }
  }

  @override
  Future<List<ExerciseLogEntity>> getExerciseHistory(
    String exerciseName, {
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final logs = await _dataSource.getExerciseHistory(
        exerciseName,
        limit: limit,
      );
      return logs.map((l) => l.toEntity()).toList();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get exercise history: $e');
    }
  }

  // ========== Progress Operations ==========

  @override
  Future<List<String>> getAllExerciseNames() async {
    try {
      return await _dataSource.getAllExerciseNames();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get exercise names: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getExercisePersonalRecords(
    String exerciseName,
  ) async {
    try {
      final logs = await _dataSource.getExerciseHistory(exerciseName);
      if (logs.isEmpty) {
        return {
          'maxWeight': 0.0,
          'maxReps': 0,
          'maxVolume': 0.0,
          'lastTrained': null,
        };
      }

      double maxWeight = 0.0;
      int maxReps = 0;
      double maxVolume = 0.0;

      for (final log in logs) {
        if (log.maxWeight > maxWeight) maxWeight = log.maxWeight;
        if (log.maxReps > maxReps) maxReps = log.maxReps;
        if (log.totalVolume > maxVolume) maxVolume = log.totalVolume;
      }

      return {
        'maxWeight': maxWeight,
        'maxReps': maxReps,
        'maxVolume': maxVolume,
        'lastTrained': logs.first.exerciseName,
      };
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get personal records: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getExerciseProgressData(
    String exerciseName, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final sessions = await _dataSource.getWorkoutHistory();
      final progressData = <Map<String, dynamic>>[];

      for (final session in sessions) {
        final exerciseLogs = session.exerciseLogs
            .where((log) => log.exerciseName == exerciseName);

        for (final log in exerciseLogs) {
          progressData.add({
            'date': session.startTime,
            'maxWeight': log.maxWeight,
            'totalVolume': log.totalVolume,
            'maxReps': log.maxReps,
            'sets': log.sets.length,
          });
        }
      }

      progressData.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      return progressData;
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get progress data: $e');
    }
  }

  // ========== Statistics Operations ==========

  @override
  Future<int> getTotalWorkoutCount() async {
    try {
      final sessions = await _dataSource.getWorkoutHistory();
      return sessions.length;
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get workout count: $e');
    }
  }

  @override
  Future<double> getTotalVolume() async {
    try {
      final sessions = await _dataSource.getWorkoutHistory();
      double totalVolume = 0.0;
      for (final session in sessions) {
        totalVolume += session.totalVolume;
      }
      return totalVolume;
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get total volume: $e');
    }
  }

  @override
  Future<int> getCurrentStreak() async {
    try {
      final sessions = await _dataSource.getWorkoutHistory();
      if (sessions.isEmpty) return 0;

      int streak = 0;
      DateTime? lastDate;

      for (final session in sessions) {
        final sessionDate = DateTime(
          session.startTime.year,
          session.startTime.month,
          session.startTime.day,
        );

        if (lastDate == null) {
          streak = 1;
          lastDate = sessionDate;
        } else {
          final difference = lastDate.difference(sessionDate).inDays;
          if (difference == 1) {
            streak++;
            lastDate = sessionDate;
          } else {
            break;
          }
        }
      }

      return streak;
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get streak: $e');
    }
  }
}
