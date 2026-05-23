import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_tracker/features/stats/data/repositories/statistics_repository_provider.dart';
import 'package:reading_tracker/features/stats/domain/entities/statistics_summary.dart';
import 'package:reading_tracker/features/stats/domain/usecases/get_statistics_summary.dart';

final getStatisticsSummaryProvider = Provider<GetStatisticsSummary>((ref) {
  return GetStatisticsSummary(ref.watch(statisticsRepositoryProvider));
});

final statisticsSummaryProvider = FutureProvider<StatisticsSummary>((ref) {
  return ref.watch(getStatisticsSummaryProvider)();
});
