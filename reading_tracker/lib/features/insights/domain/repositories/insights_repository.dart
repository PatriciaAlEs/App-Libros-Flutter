import '../entities/reading_insights_summary.dart';

abstract interface class InsightsRepository {
  Future<ReadingInsightsSummary> getSummary();
}
