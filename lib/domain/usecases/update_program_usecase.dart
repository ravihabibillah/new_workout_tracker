import '../entities/program_entity.dart';
import '../repositories/i_workout_repository.dart';

class UpdateProgramUseCase {
  final IWorkoutRepository _repository;

  UpdateProgramUseCase(this._repository);

  Future<ProgramEntity> call(ProgramEntity program) async {
    return await _repository.updateProgram(program);
  }
}
