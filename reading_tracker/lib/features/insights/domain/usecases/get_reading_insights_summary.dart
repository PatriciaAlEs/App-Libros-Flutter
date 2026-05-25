import '../entities/reading_insights_summary.dart';
import '../repositories/insights_repository.dart';

class GetReadingInsightsSummary {
  const GetReadingInsightsSummary(this._repository);

  final InsightsRepository _repository;

  Future<ReadingInsightsSummary> call() => _repository.getSummary();
}
