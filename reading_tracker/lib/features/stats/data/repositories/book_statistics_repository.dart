import 'package:reading_tracker/features/books/domain/repositories/book_repository.dart';
import 'package:reading_tracker/features/reading_sessions/domain/repositories/reading_session_repository.dart';
import 'package:reading_tracker/features/stats/domain/entities/statistics_summary.dart';
import 'package:reading_tracker/features/stats/domain/repositories/annual_reading_goal_repository.dart';
import 'package:reading_tracker/features/stats/domain/repositories/statistics_repository.dart';
import 'package:reading_tracker/features/stats/domain/services/statistics_calculator.dart';

class BookStatisticsRepository implements StatisticsRepository {
  const BookStatisticsRepository({
    required BookRepository bookRepository,
    required ReadingSessionRepository readingSessionRepository,
    required AnnualReadingGoalRepository annualReadingGoalRepository,
    StatisticsCalculator calculator = const StatisticsCalculator(),
  }) : _bookRepository = bookRepository,
       _readingSessionRepository = readingSessionRepository,
       _annualReadingGoalRepository = annualReadingGoalRepository,
       _calculator = calculator;

  final BookRepository _bookRepository;
  final ReadingSessionRepository _readingSessionRepository;
  final AnnualReadingGoalRepository _annualReadingGoalRepository;
  final StatisticsCalculator _calculator;

  @override
  Future<StatisticsSummary> getSummary() async {
    final books = await _bookRepository.getAllBooks();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final sessions = await _readingSessionRepository.getSessionsInRange(
      DateTime.fromMillisecondsSinceEpoch(0),
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
    );
    final annualReadingGoal = await _annualReadingGoalRepository
        .getAnnualReadingGoal();

    return _calculator.calculateFromBooks(
      books,
      sessions: sessions,
      annualReadingGoal: annualReadingGoal,
    );
  }
}
