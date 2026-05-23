import '../entities/statistics_summary.dart';
import '../repositories/statistics_repository.dart';

class GetStatisticsSummary {
  const GetStatisticsSummary(this._repository);

  final StatisticsRepository _repository;

  Future<StatisticsSummary> call() {
    return _repository.getSummary();
  }
}
