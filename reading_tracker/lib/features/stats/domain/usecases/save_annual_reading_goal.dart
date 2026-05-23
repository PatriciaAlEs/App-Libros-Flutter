import '../repositories/annual_reading_goal_repository.dart';

class SaveAnnualReadingGoal {
  const SaveAnnualReadingGoal(this._repository);

  final AnnualReadingGoalRepository _repository;

  Future<void> call(int goal) {
    return _repository.saveAnnualReadingGoal(goal);
  }
}
