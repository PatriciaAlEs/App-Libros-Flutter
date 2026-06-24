import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_tracker/core/analytics/readpp_analytics.dart';
import 'package:reading_tracker/features/stats/data/repositories/annual_reading_goal_repository_provider.dart';
import 'package:reading_tracker/features/stats/data/repositories/statistics_repository_provider.dart';
import 'package:reading_tracker/features/stats/domain/entities/statistics_summary.dart';
import 'package:reading_tracker/features/stats/domain/usecases/get_statistics_summary.dart';
import 'package:reading_tracker/features/stats/domain/usecases/save_annual_reading_goal.dart';

final getStatisticsSummaryProvider = Provider<GetStatisticsSummary>((ref) {
  return GetStatisticsSummary(ref.watch(statisticsRepositoryProvider));
});

final statisticsSummaryProvider = FutureProvider<StatisticsSummary>((ref) {
  return ref.watch(getStatisticsSummaryProvider)();
});

final saveAnnualReadingGoalProvider = Provider<SaveAnnualReadingGoal>((ref) {
  return SaveAnnualReadingGoal(
    ref.watch(annualReadingGoalRepositoryProvider),
    analytics: ref.watch(readPpAnalyticsProvider),
  );
});
