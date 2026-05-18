import '../entities/workout_session_entity.dart';
import '../repositories/i_workout_repository.dart';

class CompleteWorkoutUseCase {
  final IWorkoutRepository _repository;

  CompleteWorkoutUseCase(this._repository);

  Future<WorkoutSessionEntity> call(String sessionId) async {
    return await _repository.completeWorkoutSession(sessionId);
  }
}
