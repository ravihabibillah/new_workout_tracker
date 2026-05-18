import '../entities/program_entity.dart';
import '../repositories/i_workout_repository.dart';

/// Use case for getting all workout programs
class GetProgramsUseCase {
  final IWorkoutRepository _repository;

  GetProgramsUseCase(this._repository);

  Future<List<ProgramEntity>> call() async {
    return await _repository.getPrograms();
  }
}
