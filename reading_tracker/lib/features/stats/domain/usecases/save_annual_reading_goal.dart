import '../../../../core/analytics/readpp_analytics.dart';
import '../../../sync/domain/services/local_sync_tracker.dart';
import '../repositories/annual_reading_goal_repository.dart';

class SaveAnnualReadingGoal {
  const SaveAnnualReadingGoal(
    this._repository, {
    ReadPpAnalytics analytics = const ReadPpAnalytics.disabled(),
    LocalSyncTracker? syncTracker,
  }) : _analytics = analytics,
       _syncTracker = syncTracker;

  final AnnualReadingGoalRepository _repository;
  final ReadPpAnalytics _analytics;
  final LocalSyncTracker? _syncTracker;

  Future<void> call(int goal) async {
    final previousGoal = await _repository.getAnnualReadingGoal();
    await _repository.saveAnnualReadingGoal(goal);
    if (previousGoal == null) {
      await _syncTracker?.trackAnnualGoalCreated();
      await _analytics.trackAnnualGoalCreated(goalBooks: goal);
    } else {
      await _syncTracker?.trackAnnualGoalUpdated();
      await _analytics.trackAnnualGoalUpdated(goalBooks: goal);
    }
  }
}
