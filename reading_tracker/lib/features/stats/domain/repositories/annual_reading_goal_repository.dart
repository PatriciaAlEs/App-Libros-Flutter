abstract interface class AnnualReadingGoalRepository {
  Future<int?> getAnnualReadingGoal();
  Future<void> saveAnnualReadingGoal(int goal);
}
