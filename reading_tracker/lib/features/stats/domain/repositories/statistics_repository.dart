import '../entities/statistics_summary.dart';

abstract interface class StatisticsRepository {
  Future<StatisticsSummary> getSummary();
}
