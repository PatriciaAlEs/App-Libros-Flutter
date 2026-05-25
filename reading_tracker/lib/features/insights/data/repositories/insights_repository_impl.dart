import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/books/domain/repositories/book_repository.dart';
import 'package:reading_tracker/features/insights/domain/entities/reading_insights_summary.dart';
import 'package:reading_tracker/features/insights/domain/repositories/insights_repository.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/reading_sessions/domain/repositories/reading_session_repository.dart';

class InsightsRepositoryImpl implements InsightsRepository {
  const InsightsRepositoryImpl({
    required BookRepository bookRepository,
    required ReadingSessionRepository readingSessionRepository,
    DateTime Function()? now,
  }) : _bookRepository = bookRepository,
       _readingSessionRepository = readingSessionRepository,
       _now = now ?? DateTime.now;

  final BookRepository _bookRepository;
  final ReadingSessionRepository _readingSessionRepository;
  final DateTime Function() _now;

  @override
  Future<ReadingInsightsSummary> getSummary() async {
    final books = await _bookRepository.getAllBooks();
    if (books.isEmpty) return const ReadingInsightsSummary.empty();

    final today = _dateOnly(_now());
    final tomorrow = today.add(const Duration(days: 1));
    final sessions = await _readingSessionRepository.getSessionsInRange(
      DateTime.fromMillisecondsSinceEpoch(0),
      tomorrow,
    );

    return _calculateSummary(books, sessions, today);
  }

  ReadingInsightsSummary _calculateSummary(
    List<Book> books,
    List<ReadingSession> sessions,
    DateTime today,
  ) {
    final booksById = {for (final book in books) book.id: book};
    final pagesByBookId = <String, int>{};
    final pagesByAuthor = <String, int>{};
    final pagesByGenre = <String, int>{};
    final pagesSessions = sessions
        .where(
          (session) =>
              session.pagesRead > 0 && !_dateOnly(session.date).isAfter(today),
        )
        .toList();
    final minuteSessions = sessions
        .where(
          (session) =>
              session.minutes > 0 && !_dateOnly(session.date).isAfter(today),
        )
        .toList();

    for (final session in pagesSessions) {
      final book = booksById[session.bookId];
      if (book == null) continue;

      pagesByBookId.update(
        book.id,
        (pages) => pages + session.pagesRead,
        ifAbsent: () => session.pagesRead,
      );

      final author = _cleanValue(book.author);
      if (author != null) {
        pagesByAuthor.update(
          author,
          (pages) => pages + session.pagesRead,
          ifAbsent: () => session.pagesRead,
        );
      }

      final genre = _cleanValue(book.genre);
      if (genre != null) {
        pagesByGenre.update(
          genre,
          (pages) => pages + session.pagesRead,
          ifAbsent: () => session.pagesRead,
        );
      }
    }

    final topBookEntry = _topEntry(pagesByBookId);
    final topBook = topBookEntry == null ? null : booksById[topBookEntry.key];
    final topAuthorEntry = _topEntry(pagesByAuthor);
    final topGenreEntry = _topEntry(pagesByGenre);
    final finishPrediction = _calculateFinishPrediction(
      books,
      pagesSessions,
      today,
    );
    final annualForecast = _calculateAnnualForecast(books, today);

    return ReadingInsightsSummary(
      mostReadBookTitle: topBook?.title,
      mostReadBookPages: topBookEntry?.value ?? 0,
      mostReadAuthor: topAuthorEntry?.key,
      mostReadAuthorPages: topAuthorEntry?.value ?? 0,
      favoriteGenre: topGenreEntry?.key,
      favoriteGenrePages: topGenreEntry?.value ?? 0,
      averagePagesPerSession: _averagePagesPerSession(pagesSessions),
      averageMinutesPerSession: _averageMinutesPerSession(minuteSessions),
      averagePagesPerActiveDay: _averagePagesPerActiveDay(pagesSessions),
      finishPredictionBookTitle: finishPrediction?.book.title,
      finishPredictionRemainingPages: finishPrediction?.remainingPages,
      finishPredictionRecentPagesPerDay: finishPrediction?.recentPagesPerDay,
      finishPredictionDaysRemaining: finishPrediction?.daysRemaining,
      finishPredictionDate: finishPrediction?.estimatedFinishDate,
      completedBooksThisYear: annualForecast.completedBooksThisYear,
      annualBooksForecast: annualForecast.projectedBooks,
    );
  }

  double? _averagePagesPerSession(List<ReadingSession> sessions) {
    if (sessions.isEmpty) return null;
    final totalPages = sessions.fold<int>(
      0,
      (total, session) => total + session.pagesRead,
    );
    return totalPages / sessions.length;
  }

  double? _averageMinutesPerSession(List<ReadingSession> sessions) {
    if (sessions.isEmpty) return null;
    final totalMinutes = sessions.fold<int>(
      0,
      (total, session) => total + session.minutes,
    );
    return totalMinutes / sessions.length;
  }

  double? _averagePagesPerActiveDay(List<ReadingSession> sessions) {
    if (sessions.isEmpty) return null;

    final pagesByDay = <DateTime, int>{};
    for (final session in sessions) {
      final date = _dateOnly(session.date);
      pagesByDay.update(
        date,
        (pages) => pages + session.pagesRead,
        ifAbsent: () => session.pagesRead,
      );
    }

    final totalPages = pagesByDay.values.fold<int>(
      0,
      (total, pages) => total + pages,
    );
    return totalPages / pagesByDay.length;
  }

  _FinishPrediction? _calculateFinishPrediction(
    List<Book> books,
    List<ReadingSession> sessions,
    DateTime today,
  ) {
    final book = _currentReadingBookForPrediction(books);
    if (book == null) return null;

    final totalPages = book.totalPages;
    final currentPage = book.currentPage ?? 0;
    if (totalPages == null || totalPages <= 0 || currentPage >= totalPages) {
      return null;
    }

    final remainingPages = totalPages - currentPage;
    final recentStart = today.subtract(const Duration(days: 29));
    final recentSessions = sessions.where((session) {
      final date = _dateOnly(session.date);
      return session.bookId == book.id &&
          !date.isBefore(recentStart) &&
          !date.isAfter(today);
    }).toList();
    final recentPagesPerDay = _averagePagesPerActiveDay(recentSessions);
    if (recentPagesPerDay == null || recentPagesPerDay <= 0) return null;

    final daysRemaining = (remainingPages / recentPagesPerDay).ceil();
    return _FinishPrediction(
      book: book,
      remainingPages: remainingPages,
      recentPagesPerDay: recentPagesPerDay,
      daysRemaining: daysRemaining,
      estimatedFinishDate: today.add(Duration(days: daysRemaining)),
    );
  }

  Book? _currentReadingBookForPrediction(List<Book> books) {
    final candidates = books.where((book) {
      final totalPages = book.totalPages;
      final currentPage = book.currentPage ?? 0;
      return book.status == BookStatus.reading &&
          totalPages != null &&
          totalPages > 0 &&
          currentPage < totalPages;
    }).toList();
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final aDate = a.updatedAt ?? a.startedAt ?? a.createdAt;
      final bDate = b.updatedAt ?? b.startedAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return candidates.first;
  }

  _AnnualForecast _calculateAnnualForecast(List<Book> books, DateTime today) {
    final completedBooksThisYear = books.where((book) {
      final finishedAt = book.finishedAt;
      final finishedDay = finishedAt == null ? null : _dateOnly(finishedAt);
      return book.status == BookStatus.completed &&
          finishedDay != null &&
          finishedDay.year == today.year &&
          !finishedDay.isAfter(today);
    }).length;
    if (completedBooksThisYear == 0) {
      return const _AnnualForecast(completedBooksThisYear: 0);
    }

    final yearStart = DateTime(today.year);
    final nextYearStart = DateTime(today.year + 1);
    final elapsedDays = today.difference(yearStart).inDays + 1;
    final daysInYear = nextYearStart.difference(yearStart).inDays;
    final projectedBooks = (completedBooksThisYear / elapsedDays * daysInYear)
        .round();

    return _AnnualForecast(
      completedBooksThisYear: completedBooksThisYear,
      projectedBooks: projectedBooks < completedBooksThisYear
          ? completedBooksThisYear
          : projectedBooks,
    );
  }

  MapEntry<String, int>? _topEntry(Map<String, int> pagesByKey) {
    if (pagesByKey.isEmpty) return null;

    final entries = pagesByKey.entries.toList()
      ..sort((a, b) {
        final pagesComparison = b.value.compareTo(a.value);
        if (pagesComparison != 0) return pagesComparison;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return entries.first;
  }

  String? _cleanValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _FinishPrediction {
  const _FinishPrediction({
    required this.book,
    required this.remainingPages,
    required this.recentPagesPerDay,
    required this.daysRemaining,
    required this.estimatedFinishDate,
  });

  final Book book;
  final int remainingPages;
  final double recentPagesPerDay;
  final int daysRemaining;
  final DateTime estimatedFinishDate;
}

class _AnnualForecast {
  const _AnnualForecast({
    required this.completedBooksThisYear,
    this.projectedBooks,
  });

  final int completedBooksThisYear;
  final int? projectedBooks;
}
