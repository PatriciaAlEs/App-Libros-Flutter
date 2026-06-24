import '../../../../core/analytics/readpp_analytics.dart';
import '../repositories/annual_reading_goal_repository.dart';

class SaveAnnualReadingGoal {
  const SaveAnnualReadingGoal(
    this._repository, {
    ReadPpAnalytics analytics = const ReadPpAnalytics.disabled(),
  }) : _analytics = analytics;

  final AnnualReadingGoalRepository _repository;
  final ReadPpAnalytics _analytics;

  Future<void> call(int goal) async {
    final previousGoal = await _repository.getAnnualReadingGoal();
    await _repository.saveAnnualReadingGoal(goal);
    if (previousGoal == null) {
      await _analytics.trackAnnualGoalCreated(goalBooks: goal);
    } else {
      await _analytics.trackAnnualGoalUpdated(goalBooks: goal);
    }
  }
}
