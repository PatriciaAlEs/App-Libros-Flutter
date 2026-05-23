import 'package:reading_tracker/features/books/domain/repositories/book_repository.dart';
import 'package:reading_tracker/features/stats/domain/entities/statistics_summary.dart';
import 'package:reading_tracker/features/stats/domain/repositories/statistics_repository.dart';
import 'package:reading_tracker/features/stats/domain/services/statistics_calculator.dart';

class BookStatisticsRepository implements StatisticsRepository {
  const BookStatisticsRepository({
    required BookRepository bookRepository,
    StatisticsCalculator calculator = const StatisticsCalculator(),
  }) : _bookRepository = bookRepository,
       _calculator = calculator;

  final BookRepository _bookRepository;
  final StatisticsCalculator _calculator;

  @override
  Future<StatisticsSummary> getSummary() async {
    final books = await _bookRepository.getAllBooks();
    return _calculator.calculateFromBooks(books);
  }
}
