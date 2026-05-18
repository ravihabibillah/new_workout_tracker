import '../entities/workout_session_entity.dart';
import '../repositories/i_workout_repository.dart';

class StartWorkoutUseCase {
  final IWorkoutRepository _repository;

  StartWorkoutUseCase(this._repository);

  Future<WorkoutSessionEntity> call({
    required String programId,
    required String programName,
  }) async {
    return await _repository.startWorkoutSession(
      programId: programId,
      programName: programName,
    );
  }
}
