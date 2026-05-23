import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';

import '../entities/statistics_summary.dart';

class StatisticsCalculator {
  const StatisticsCalculator();

  StatisticsSummary calculateFromBooks(List<Book> books) {
    if (books.isEmpty) return const StatisticsSummary.empty();

    final completedBooks = _countByStatus(books, BookStatus.completed);
    final readingBooks = _countByStatus(books, BookStatus.reading);
    final pausedBooks = _countByStatus(books, BookStatus.paused);
    final abandonedBooks = _countByStatus(books, BookStatus.abandoned);
    final toReadBooks = _countByStatus(books, BookStatus.pending);

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
}
