import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/books/domain/repositories/book_repository.dart';
import 'package:reading_tracker/features/insights/domain/entities/reading_insights_summary.dart';
import 'package:reading_tracker/features/insights/domain/repositories/insights_repository.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/reading_sessions/domain/repositories/reading_session_repository.dart';
import 'package:reading_tracker/features/stats/domain/services/statistics_calculator.dart';

class InsightsRepositoryImpl implements InsightsRepository {
  const InsightsRepositoryImpl({
    required BookRepository bookRepository,
    required ReadingSessionRepository readingSessionRepository,
    DateTime Function()? now,
    StatisticsCalculator statisticsCalculator = const StatisticsCalculator(),
  }) : _bookRepository = bookRepository,
       _readingSessionRepository = readingSessionRepository,
       _now = now ?? DateTime.now,
       _statisticsCalculator = statisticsCalculator;

  final BookRepository _bookRepository;
  final ReadingSessionRepository _readingSessionRepository;
  final DateTime Function() _now;
  final StatisticsCalculator _statisticsCalculator;

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
    final mostReadAuthorBooks = topAuthorEntry == null
        ? const <ReadingInsightBookPreview>[]
        : _booksForAuthor(
            books,
            pagesByBookId.keys.toSet(),
            topAuthorEntry.key,
          );
    final topGenreEntry = _topEntry(pagesByGenre);
    final finishPrediction = _calculateFinishPrediction(
      books,
      pagesSessions,
      today,
    );
    final annualForecast = _calculateAnnualForecast(books, today);
    final topReadsOfYear = _calculateTopReadsOfYear(books, sessions, today);
    final personalRanking = _calculatePersonalRanking(booksById, pagesSessions);
    final curiosities = _calculateCuriosities(sessions, today);
    final statisticsSummary = _statisticsCalculator.calculateFromBooks(
      books,
      sessions: sessions,
      now: today,
    );

    return ReadingInsightsSummary(
      mostReadBookTitle: topBook?.title,
      mostReadBookPages: topBookEntry?.value ?? 0,
      mostReadAuthor: topAuthorEntry?.key,
      mostReadAuthorPages: topAuthorEntry?.value ?? 0,
      mostReadAuthorBooks: mostReadAuthorBooks,
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
      topRatedBookTitle: topReadsOfYear.topRatedBook?.title,
      topRatedBookRating: topReadsOfYear.topRatedBook?.rating,
      topRatedBooks: topReadsOfYear.topRatedBooks,
      longestBookTitle: topReadsOfYear.longestBook?.title,
      longestBookPages: topReadsOfYear.longestBook?.totalPages,
      shortestBookTitle: topReadsOfYear.shortestBook?.title,
      shortestBookPages: topReadsOfYear.shortestBook?.totalPages,
      mostTimeBookTitle: topReadsOfYear.mostTimeBook?.title,
      mostTimeBookMinutes: topReadsOfYear.mostTimeMinutes,
      mostSessionsBookTitle: topReadsOfYear.mostSessionsBook?.title,
      mostSessionsCount: topReadsOfYear.mostSessionsCount,
      topAuthors: personalRanking.topAuthors,
      topGenres: personalRanking.topGenres,
      topBooks: personalRanking.topBooks,
      mostActiveMonth: curiosities.mostActiveMonth,
      mostActiveMonthPages: curiosities.mostActiveMonthPages,
      mostActiveMonthMinutes: curiosities.mostActiveMonthMinutes,
      usualReadingTimeSlot: curiosities.usualReadingTimeSlot,
      usualReadingTimeSlotSessions: curiosities.usualReadingTimeSlotSessions,
      mostActiveDay: curiosities.mostActiveDay,
      mostActiveDayPages: curiosities.mostActiveDayPages,
      mostActiveDayMinutes: curiosities.mostActiveDayMinutes,
      bestStreakDays: statisticsSummary.bestStreakDays,
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

  List<ReadingInsightBookPreview> _booksForAuthor(
    List<Book> books,
    Set<String> activeBookIds,
    String author,
  ) {
    final normalizedAuthor = _cleanValue(author);
    if (normalizedAuthor == null) return const [];

    final matchingBooks =
        books.where((book) {
          return _cleanValue(book.author) == normalizedAuthor &&
              (book.status == BookStatus.completed ||
                  activeBookIds.contains(book.id));
        }).toList()..sort((a, b) {
          final aCompleted = a.status == BookStatus.completed ? 0 : 1;
          final bCompleted = b.status == BookStatus.completed ? 0 : 1;
          if (aCompleted != bCompleted) return aCompleted.compareTo(bCompleted);
          final aDate = a.completedDate ?? a.updatedAt ?? a.createdAt;
          final bDate = b.completedDate ?? b.updatedAt ?? b.createdAt;
          return bDate.compareTo(aDate);
        });

    return matchingBooks
        .map(
          (book) => ReadingInsightBookPreview(
            title: book.title,
            author: book.author,
            coverUrl: book.coverUrl,
          ),
        )
        .toList();
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

  _TopReadsOfYear _calculateTopReadsOfYear(
    List<Book> books,
    List<ReadingSession> sessions,
    DateTime today,
  ) {
    final completedThisYear = books.where((book) {
      final finishedAt = book.finishedAt;
      final finishedDay = finishedAt == null ? null : _dateOnly(finishedAt);
      return book.status == BookStatus.completed &&
          finishedDay != null &&
          finishedDay.year == today.year &&
          !finishedDay.isAfter(today);
    }).toList();
    final sessionsThisYear = sessions.where((session) {
      final date = _dateOnly(session.date);
      return date.year == today.year && !date.isAfter(today);
    }).toList();
    final booksById = {for (final book in books) book.id: book};
    final minutesByBookId = <String, int>{};
    final sessionsByBookId = <String, int>{};

    for (final session in sessionsThisYear) {
      if (!booksById.containsKey(session.bookId)) continue;
      if (session.minutes > 0) {
        minutesByBookId.update(
          session.bookId,
          (minutes) => minutes + session.minutes,
          ifAbsent: () => session.minutes,
        );
      }
      sessionsByBookId.update(
        session.bookId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final mostTimeEntry = _topEntry(minutesByBookId);
    final mostSessionsEntry = _topEntry(sessionsByBookId);

    return _TopReadsOfYear(
      topRatedBook: _topRatedBook(completedThisYear),
      topRatedBooks: _topRatedBooks(completedThisYear),
      longestBook: _longestBook(completedThisYear),
      shortestBook: _shortestBook(completedThisYear),
      mostTimeBook: mostTimeEntry == null ? null : booksById[mostTimeEntry.key],
      mostTimeMinutes: mostTimeEntry?.value,
      mostSessionsBook: mostSessionsEntry == null
          ? null
          : booksById[mostSessionsEntry.key],
      mostSessionsCount: mostSessionsEntry?.value,
    );
  }

  Book? _topRatedBook(List<Book> completedBooks) {
    final ratedBooks = completedBooks
        .where((book) => book.rating != null)
        .toList();
    if (ratedBooks.isEmpty) return null;

    ratedBooks.sort((a, b) {
      final ratingComparison = b.rating!.compareTo(a.rating!);
      if (ratingComparison != 0) return ratingComparison;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return ratedBooks.first;
  }

  List<ReadingInsightRatedBook> _topRatedBooks(List<Book> completedBooks) {
    final ratedBooks = completedBooks
        .where((book) => book.rating != null)
        .toList();
    if (ratedBooks.isEmpty) return const [];

    ratedBooks.sort((a, b) {
      final ratingComparison = b.rating!.compareTo(a.rating!);
      if (ratingComparison != 0) return ratingComparison;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return ratedBooks
        .take(3)
        .map(
          (book) => ReadingInsightRatedBook(
            title: book.title,
            rating: book.rating!,
            author: book.author,
            coverUrl: book.coverUrl,
            review: book.notes,
          ),
        )
        .toList();
  }

  Book? _longestBook(List<Book> completedBooks) {
    final booksWithPages = completedBooks
        .where((book) => book.totalPages != null && book.totalPages! > 0)
        .toList();
    if (booksWithPages.isEmpty) return null;

    booksWithPages.sort((a, b) {
      final pagesComparison = b.totalPages!.compareTo(a.totalPages!);
      if (pagesComparison != 0) return pagesComparison;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return booksWithPages.first;
  }

  Book? _shortestBook(List<Book> completedBooks) {
    final booksWithPages = completedBooks
        .where((book) => book.totalPages != null && book.totalPages! > 0)
        .toList();
    if (booksWithPages.isEmpty) return null;

    booksWithPages.sort((a, b) {
      final pagesComparison = a.totalPages!.compareTo(b.totalPages!);
      if (pagesComparison != 0) return pagesComparison;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return booksWithPages.first;
  }

  _PersonalRanking _calculatePersonalRanking(
    Map<String, Book> booksById,
    List<ReadingSession> sessions,
  ) {
    final pagesByAuthor = <String, int>{};
    final pagesByGenre = <String, int>{};
    final pagesByBookId = <String, int>{};

    for (final session in sessions) {
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

    return _PersonalRanking(
      topAuthors: _topRankingItems(pagesByAuthor),
      topGenres: _topRankingItems(pagesByGenre),
      topBooks: _topBookRankingItems(pagesByBookId, booksById),
    );
  }

  _ReadingCuriosities _calculateCuriosities(
    List<ReadingSession> sessions,
    DateTime today,
  ) {
    final validSessions = sessions
        .where(
          (session) =>
              !_dateOnly(session.date).isAfter(today) &&
              (session.pagesRead > 0 || session.minutes > 0),
        )
        .toList();
    if (validSessions.isEmpty) return const _ReadingCuriosities();

    final activityByMonth = <DateTime, _ActivityTotals>{};
    final activityByDay = <DateTime, _ActivityTotals>{};
    final sessionsByTimeSlot = <String, int>{};

    for (final session in validSessions) {
      final day = _dateOnly(session.date);
      final month = DateTime(day.year, day.month);
      activityByMonth
          .putIfAbsent(month, () => _ActivityTotals())
          .add(session.pagesRead, session.minutes);
      activityByDay
          .putIfAbsent(day, () => _ActivityTotals())
          .add(session.pagesRead, session.minutes);

      final timeSlot = _timeSlotFor(session.createdAt);
      sessionsByTimeSlot.update(
        timeSlot,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final topMonth = _topActivityEntry(activityByMonth);
    final topDay = _topActivityEntry(activityByDay);
    final topTimeSlot = _topEntry(sessionsByTimeSlot);

    return _ReadingCuriosities(
      mostActiveMonth: topMonth?.key,
      mostActiveMonthPages: topMonth?.value.pages ?? 0,
      mostActiveMonthMinutes: topMonth?.value.minutes ?? 0,
      usualReadingTimeSlot: topTimeSlot?.key,
      usualReadingTimeSlotSessions: topTimeSlot?.value ?? 0,
      mostActiveDay: topDay?.key,
      mostActiveDayPages: topDay?.value.pages ?? 0,
      mostActiveDayMinutes: topDay?.value.minutes ?? 0,
    );
  }

  List<ReadingInsightRankingItem> _topBookRankingItems(
    Map<String, int> pagesByBookId,
    Map<String, Book> booksById,
  ) {
    final entries = pagesByBookId.entries.toList()
      ..sort((a, b) {
        final valueComparison = b.value.compareTo(a.value);
        if (valueComparison != 0) return valueComparison;
        final aTitle = booksById[a.key]?.title ?? a.key;
        final bTitle = booksById[b.key]?.title ?? b.key;
        return aTitle.toLowerCase().compareTo(bTitle.toLowerCase());
      });

    return entries
        .take(3)
        .map(
          (entry) => ReadingInsightRankingItem(
            label: booksById[entry.key]?.title ?? entry.key,
            value: entry.value,
          ),
        )
        .toList();
  }

  List<ReadingInsightRankingItem> _topRankingItems(Map<String, int> values) {
    final entries = values.entries.toList()
      ..sort((a, b) {
        final valueComparison = b.value.compareTo(a.value);
        if (valueComparison != 0) return valueComparison;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return entries
        .take(3)
        .map(
          (entry) =>
              ReadingInsightRankingItem(label: entry.key, value: entry.value),
        )
        .toList();
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

  MapEntry<DateTime, _ActivityTotals>? _topActivityEntry(
    Map<DateTime, _ActivityTotals> activityByDate,
  ) {
    if (activityByDate.isEmpty) return null;

    final entries = activityByDate.entries.toList()
      ..sort((a, b) {
        final pagesComparison = b.value.pages.compareTo(a.value.pages);
        if (pagesComparison != 0) return pagesComparison;
        final minutesComparison = b.value.minutes.compareTo(a.value.minutes);
        if (minutesComparison != 0) return minutesComparison;
        return b.key.compareTo(a.key);
      });

    return entries.first;
  }

  String _timeSlotFor(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour >= 5 && hour < 12) return 'Mañana';
    if (hour >= 12 && hour < 18) return 'Tarde';
    if (hour >= 18 && hour < 24) return 'Noche';
    return 'Madrugada';
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

class _TopReadsOfYear {
  const _TopReadsOfYear({
    this.topRatedBook,
    this.topRatedBooks = const [],
    this.longestBook,
    this.shortestBook,
    this.mostTimeBook,
    this.mostTimeMinutes,
    this.mostSessionsBook,
    this.mostSessionsCount,
  });

  final Book? topRatedBook;
  final List<ReadingInsightRatedBook> topRatedBooks;
  final Book? longestBook;
  final Book? shortestBook;
  final Book? mostTimeBook;
  final int? mostTimeMinutes;
  final Book? mostSessionsBook;
  final int? mostSessionsCount;
}

class _ReadingCuriosities {
  const _ReadingCuriosities({
    this.mostActiveMonth,
    this.mostActiveMonthPages = 0,
    this.mostActiveMonthMinutes = 0,
    this.usualReadingTimeSlot,
    this.usualReadingTimeSlotSessions = 0,
    this.mostActiveDay,
    this.mostActiveDayPages = 0,
    this.mostActiveDayMinutes = 0,
  });

  final DateTime? mostActiveMonth;
  final int mostActiveMonthPages;
  final int mostActiveMonthMinutes;
  final String? usualReadingTimeSlot;
  final int usualReadingTimeSlotSessions;
  final DateTime? mostActiveDay;
  final int mostActiveDayPages;
  final int mostActiveDayMinutes;
}

class _ActivityTotals {
  int pages = 0;
  int minutes = 0;

  void add(int pagesRead, int minutesRead) {
    pages += pagesRead;
    minutes += minutesRead;
  }
}

class _PersonalRanking {
  const _PersonalRanking({
    required this.topAuthors,
    required this.topGenres,
    required this.topBooks,
  });

  final List<ReadingInsightRankingItem> topAuthors;
  final List<ReadingInsightRankingItem> topGenres;
  final List<ReadingInsightRankingItem> topBooks;
}
