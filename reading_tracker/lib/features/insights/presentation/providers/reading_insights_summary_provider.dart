import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_tracker/features/insights/data/repositories/insights_repository_provider.dart';
import 'package:reading_tracker/features/insights/domain/entities/reading_insights_summary.dart';
import 'package:reading_tracker/features/insights/domain/usecases/get_reading_insights_summary.dart';

final getReadingInsightsSummaryProvider = Provider<GetReadingInsightsSummary>((
  ref,
) {
  return GetReadingInsightsSummary(ref.watch(insightsRepositoryProvider));
});

final readingInsightsSummaryProvider = FutureProvider<ReadingInsightsSummary>((
  ref,
) {
  return ref.watch(getReadingInsightsSummaryProvider)();
});
