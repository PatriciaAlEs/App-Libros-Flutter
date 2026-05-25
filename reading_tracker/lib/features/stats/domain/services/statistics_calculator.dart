import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';

import '../entities/statistics_summary.dart';

class StatisticsCalculator {
  const StatisticsCalculator();

  StatisticsSummary calculateFromBooks(
    List<Book> books, {
    List<ReadingSession> sessions = const [],
    int? annualReadingGoal,
    DateTime? now,
  }) {
    final referenceDate = now ?? DateTime.now();
    final activeDays = _activeSessionDays(sessions);

    final completedBooks = _countByStatus(books, BookStatus.completed);
    final readingBooks = _countByStatus(books, BookStatus.reading);
    final pausedBooks = _countByStatus(books, BookStatus.paused);
    final abandonedBooks = _countByStatus(books, BookStatus.abandoned);
    final toReadBooks = _countByStatus(books, BookStatus.pending);
    final completedThisYear = _calculateCompletedThisYear(
      books,
      referenceDate.year,
    );

    return StatisticsSummary(
      totalBooks: books.length,
      completedBooks: completedBooks,
      readingBooks: readingBooks,
      pausedBooks: pausedBooks,
      abandonedBooks: abandonedBooks,
      toReadBooks: toReadBooks,
      totalPagesRead: _calculateTotalPagesRead(books),
      averageRating: _calculateAverageRating(books),
      currentlyReadingCount: readingBooks,
      annualReadingGoal: annualReadingGoal,
      completedThisYear: completedThisYear,
      annualGoalProgress: _calculateAnnualGoalProgress(
        completedThisYear: completedThisYear,
        annualReadingGoal: annualReadingGoal,
      ),
      booksRemainingForAnnualGoal: _calculateRemainingForAnnualGoal(
        completedThisYear: completedThisYear,
        annualReadingGoal: annualReadingGoal,
      ),
      isAnnualGoalReached: _isAnnualGoalReached(
        completedThisYear: completedThisYear,
        annualReadingGoal: annualReadingGoal,
      ),
      currentStreakDays: _calculateCurrentStreak(activeDays, referenceDate),
      bestStreakDays: _calculateBestStreak(activeDays),
    );
  }

  int _countByStatus(List<Book> books, BookStatus status) {
    return books.where((book) => book.status == status).length;
  }

  int _calculateTotalPagesRead(List<Book> books) {
    return books.fold<int>(0, (total, book) {
      var pages = 0;

      if (book.status == BookStatus.completed) {
        pages = book.totalPages ?? book.currentPage ?? 0;
      } else if (book.status == BookStatus.reading ||
          book.status == BookStatus.paused ||
          book.status == BookStatus.abandoned) {
        pages = book.currentPage ?? 0;
      }

      return total + pages;
    });
  }

  double? _calculateAverageRating(List<Book> books) {
    final ratings = books
        .map((book) => book.rating)
        .whereType<double>()
        .toList();

    if (ratings.isEmpty) return null;

    final total = ratings.fold<double>(0, (sum, rating) => sum + rating);
    return total / ratings.length;
  }

  int _calculateCompletedThisYear(List<Book> books, int year) {
    return books.where((book) {
      final finishedAt = book.finishedAt;
      return book.status == BookStatus.completed &&
          finishedAt != null &&
          finishedAt.year == year;
    }).length;
  }

  double? _calculateAnnualGoalProgress({
    required int completedThisYear,
    required int? annualReadingGoal,
  }) {
    if (annualReadingGoal == null || annualReadingGoal <= 0) return null;
    return (completedThisYear / annualReadingGoal * 100)
        .clamp(0, 100)
        .toDouble();
  }

  int? _calculateRemainingForAnnualGoal({
    required int completedThisYear,
    required int? annualReadingGoal,
  }) {
    if (annualReadingGoal == null || annualReadingGoal <= 0) return null;
    final remaining = annualReadingGoal - completedThisYear;
    return remaining <= 0 ? 0 : remaining;
  }

  bool _isAnnualGoalReached({
    required int completedThisYear,
    required int? annualReadingGoal,
  }) {
    if (annualReadingGoal == null || annualReadingGoal <= 0) return false;
    return completedThisYear >= annualReadingGoal;
  }

  Set<DateTime> _activeSessionDays(List<ReadingSession> sessions) {
    return sessions.map((session) {
      final date = session.date;
      return DateTime(date.year, date.month, date.day);
    }).toSet();
  }

  int _calculateCurrentStreak(Set<DateTime> activeDays, DateTime now) {
    if (activeDays.isEmpty) return 0;

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final streakEnd = activeDays.contains(today)
        ? today
        : activeDays.contains(yesterday)
        ? yesterday
        : null;
    if (streakEnd == null) return 0;

    var streak = 0;
    var cursor = streakEnd;
    while (activeDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _calculateBestStreak(Set<DateTime> activeDays) {
    if (activeDays.isEmpty) return 0;

    final sortedDays = activeDays.toList()..sort();
    var bestStreak = 1;
    var currentStreak = 1;

    for (var index = 1; index < sortedDays.length; index++) {
      final previousDay = sortedDays[index - 1];
      final currentDay = sortedDays[index];
      final isConsecutive = currentDay.difference(previousDay).inDays == 1;

      if (isConsecutive) {
        currentStreak += 1;
      } else {
        currentStreak = 1;
      }

      if (currentStreak > bestStreak) {
        bestStreak = currentStreak;
      }
    }

    return bestStreak;
  }
}
