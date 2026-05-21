import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';

class StatsData {
  StatsData({
    required this.totalBooks,
    required this.pendingBooks,
    required this.readingBooks,
    required this.completedBooks,
    required this.completedRate,
    required this.pagesRead,
    required this.averageReadingProgress,
    required this.booksCompletedThisMonth,
    required this.booksAddedThisMonth,
    required this.totalMinutesRead,
    required this.totalHoursRead,
    required this.averageDailyMinutes,
    required this.daysWithActivity,
    required this.bestDay,
    required this.bestDayMinutes,
    required this.currentStreakDays,
    required this.topRatedBooks,
    required this.topAuthors,
    required this.topBooksByTime,
    required this.hasSessionData,
  });

  final int totalBooks;
  final int pendingBooks;
  final int readingBooks;
  final int completedBooks;
  final double completedRate;
  final int pagesRead;
  final double averageReadingProgress;
  final int booksCompletedThisMonth;
  final int booksAddedThisMonth;
  final int totalMinutesRead;
  final double totalHoursRead;
  final double averageDailyMinutes;
  final int daysWithActivity;
  final DateTime? bestDay;
  final int bestDayMinutes;
  final int currentStreakDays;
  final List<StatBookRating> topRatedBooks;
  final List<StatAuthorSummary> topAuthors;
  final List<StatBookTime> topBooksByTime;
  final bool hasSessionData;
}

class StatBookRating {
  StatBookRating({
    required this.title,
    required this.rating,
    required this.author,
  });

  final String title;
  final double rating;
  final String? author;
}

class StatAuthorSummary {
  StatAuthorSummary({
    required this.author,
    required this.minutes,
    required this.bookCount,
  });

  final String author;
  final int minutes;
  final int bookCount;
}

class StatBookTime {
  StatBookTime({
    required this.title,
    required this.minutes,
    required this.author,
  });

  final String title;
  final int minutes;
  final String? author;
}

StatsData calculateStats(
  List<Book> books,
  List<ReadingSession> sessions, {
  DateTime? today,
}) {
  final referenceDate = today ?? DateTime.now();
  final now = DateTime(
    referenceDate.year,
    referenceDate.month,
    referenceDate.day,
  );

  final totalBooks = books.length;
  final pendingBooks = books.where((b) => b.status.name == 'pending').length;
  final readingBooks = books.where((b) => b.status.name == 'reading').length;
  final completedBooks = books
      .where((b) => b.status.name == 'completed')
      .length;
  final completedRate = totalBooks > 0
      ? (completedBooks / totalBooks * 100).toDouble()
      : 0.0;

  final booksCompletedThisMonth = books.where((book) {
    final completedDate = book.completedDate;
    return completedDate != null &&
        completedDate.year == now.year &&
        completedDate.month == now.month;
  }).length;

  final booksAddedThisMonth = books.where((book) {
    return book.createdAt.year == now.year && book.createdAt.month == now.month;
  }).length;

  final pagesRead = books.fold<int>(0, (sum, book) {
    if (book.status.name == 'completed' && book.totalPages != null) {
      return sum + book.totalPages!;
    }

    if (book.currentPage != null) {
      return sum + book.currentPage!;
    }

    return sum;
  });

  final readingBooksWithProgress = books.where((book) {
    return book.status.name == 'reading' &&
        book.currentPage != null &&
        book.totalPages != null &&
        book.totalPages! > 0;
  }).toList();

  final averageReadingProgress = readingBooksWithProgress.isEmpty
      ? 0.0
      : readingBooksWithProgress
                .map((book) => book.currentPage! / book.totalPages!)
                .reduce((a, b) => a + b) /
            readingBooksWithProgress.length *
            100;

  final sessionMinutesByDay = <DateTime, int>{};
  for (final session in sessions) {
    final sessionDay = DateTime(
      session.date.year,
      session.date.month,
      session.date.day,
    );
    sessionMinutesByDay[sessionDay] =
        (sessionMinutesByDay[sessionDay] ?? 0) + session.minutes;
  }

  final totalMinutesRead = sessions.fold<int>(
    0,
    (sum, item) => sum + item.minutes,
  );
  final daysWithActivity = sessionMinutesByDay.length;
  final averageDailyMinutes = daysWithActivity > 0
      ? totalMinutesRead / daysWithActivity
      : 0.0;

  final bestDayEntry = sessionMinutesByDay.entries
      .fold<MapEntry<DateTime, int>?>(null, (best, entry) {
        if (best == null) return entry;
        return entry.value > best.value ? entry : best;
      });

  final bestDay = bestDayEntry?.key;
  final bestDayMinutes = bestDayEntry?.value ?? 0;
  final currentStreakDays = _calculateCurrentStreak(
    sessionMinutesByDay.keys.toSet(),
    now,
  );

  final topRatedBooks = books.where((book) => book.rating != null).toList();
  topRatedBooks.sort((a, b) => a.rating!.compareTo(b.rating!));
  final topRated = topRatedBooks.reversed
      .take(5)
      .map(
        (book) => StatBookRating(
          title: book.title,
          rating: book.rating ?? 0,
          author: book.author,
        ),
      )
      .toList();

  final topAuthors = _calculateTopAuthors(books, sessions);
  final topBooksByTime = _calculateTopBooksByTime(books, sessions);

  return StatsData(
    totalBooks: totalBooks,
    pendingBooks: pendingBooks,
    readingBooks: readingBooks,
    completedBooks: completedBooks,
    completedRate: completedRate,
    pagesRead: pagesRead,
    averageReadingProgress: averageReadingProgress,
    booksCompletedThisMonth: booksCompletedThisMonth,
    booksAddedThisMonth: booksAddedThisMonth,
    totalMinutesRead: totalMinutesRead,
    totalHoursRead: totalMinutesRead / 60,
    averageDailyMinutes: averageDailyMinutes,
    daysWithActivity: daysWithActivity,
    bestDay: bestDay,
    bestDayMinutes: bestDayMinutes,
    currentStreakDays: currentStreakDays,
    topRatedBooks: topRated,
    topAuthors: topAuthors,
    topBooksByTime: topBooksByTime,
    hasSessionData: sessions.isNotEmpty,
  );
}

int _calculateCurrentStreak(Set<DateTime> activeDays, DateTime today) {
  if (activeDays.isEmpty) return 0;

  final days = activeDays
      .map((day) => DateTime(day.year, day.month, day.day))
      .toSet();
  final currentDay = DateTime(today.year, today.month, today.day);
  if (!days.contains(currentDay)) return 0;

  var streak = 0;
  var cursor = currentDay;

  while (days.contains(cursor)) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return streak;
}

List<StatAuthorSummary> _calculateTopAuthors(
  List<Book> books,
  List<ReadingSession> sessions,
) {
  final authorMinutes = <String, int>{};
  final authorBookIds = <String, Set<String>>{};
  final booksById = {for (final book in books) book.id: book};

  for (final session in sessions) {
    final book = booksById[session.bookId];
    final author = book?.author?.trim();
    if (author == null || author.isEmpty) continue;
    authorMinutes[author] = (authorMinutes[author] ?? 0) + session.minutes;
    authorBookIds.putIfAbsent(author, () => <String>{}).add(session.bookId);
  }

  return authorMinutes.entries
      .map(
        (entry) => StatAuthorSummary(
          author: entry.key,
          minutes: entry.value,
          bookCount: authorBookIds[entry.key]?.length ?? 0,
        ),
      )
      .toList()
    ..sort((a, b) => b.minutes.compareTo(a.minutes));
}

List<StatBookTime> _calculateTopBooksByTime(
  List<Book> books,
  List<ReadingSession> sessions,
) {
  final minutesByBook = <String, int>{};
  final booksById = {for (final book in books) book.id: book};

  for (final session in sessions) {
    minutesByBook[session.bookId] =
        (minutesByBook[session.bookId] ?? 0) + session.minutes;
  }

  return minutesByBook.entries.map((entry) {
    final book = booksById[entry.key];
    return StatBookTime(
      title: book?.title ?? 'Unknown',
      author: book?.author,
      minutes: entry.value,
    );
  }).toList()..sort((a, b) => b.minutes.compareTo(a.minutes));
}
