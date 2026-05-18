import '../entities/program_entity.dart';
import '../repositories/i_workout_repository.dart';

/// Use case for creating a new workout program
class CreateProgramUseCase {
  final IWorkoutRepository _repository;

  CreateProgramUseCase(this._repository);

  Future<ProgramEntity> call(ProgramEntity program) async {
    return await _repository.createProgram(program);
  }
}
