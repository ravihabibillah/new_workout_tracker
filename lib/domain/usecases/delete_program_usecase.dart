import '../repositories/i_workout_repository.dart';

class DeleteProgramUseCase {
  final IWorkoutRepository _repository;

  DeleteProgramUseCase(this._repository);

  Future<void> call(String programId) async {
    return await _repository.deleteProgram(programId);
  }
}
