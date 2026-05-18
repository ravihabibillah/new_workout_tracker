import '../repositories/i_workout_repository.dart';

class GetExerciseProgressUseCase {
  final IWorkoutRepository _repository;

  GetExerciseProgressUseCase(this._repository);

  Future<List<Map<String, dynamic>>> call(
    String exerciseName, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _repository.getExerciseProgressData(
      exerciseName,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
