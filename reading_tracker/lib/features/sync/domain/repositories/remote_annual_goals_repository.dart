import '../entities/remote_annual_goal.dart';

abstract interface class RemoteAnnualGoalsRepository {
  Future<List<RemoteAnnualGoal>> getAnnualGoals({
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  });

  Future<List<RemoteAnnualGoal>> upsertAnnualGoals(
    List<RemoteAnnualGoal> goals,
  );
  Future<void> deleteAnnualGoal({
    required String userId,
    required String goalId,
  });
}
