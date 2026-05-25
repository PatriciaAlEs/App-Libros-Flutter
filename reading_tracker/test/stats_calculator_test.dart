import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/stats/domain/stats_calculator.dart';
import 'package:reading_tracker/features/stats/domain/services/statistics_calculator.dart';

void main() {
  test('calculateStats computes summary correctly', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    final books = [
      Book(
        id: '1',
        title: 'Book One',
        author: 'Author A',
        createdAt: today,
        totalPages: 200,
        currentPage: 100,
        rating: 4.0,
        status: BookStatus.reading,
      ),
      Book(
        id: '2',
        title: 'Book Two',
        author: 'Author B',
        createdAt: today,
        totalPages: 120,
        currentPage: 120,
        rating: 4.5,
        status: BookStatus.completed,
        completedDate: yesterday,
      ),
      Book(
        id: '3',
        title: 'Book Three',
        author: 'Author A',
        createdAt: today,
        status: BookStatus.pending,
      ),
    ];

    final sessions = [
      ReadingSession(
        id: 's1',
        bookId: '1',
        date: twoDaysAgo,
        minutes: 30,
        createdAt: twoDaysAgo,
      ),
      ReadingSession(
        id: 's2',
        bookId: '1',
        date: yesterday,
        minutes: 40,
        createdAt: yesterday,
      ),
      ReadingSession(
        id: 's3',
        bookId: '2',
        date: yesterday,
        minutes: 50,
        createdAt: yesterday,
      ),
    ];

    final stats = calculateStats(books, sessions, today: today);

    expect(stats.totalBooks, 3);
    expect(stats.pendingBooks, 1);
    expect(stats.readingBooks, 1);
    expect(stats.completedBooks, 1);
    expect(stats.booksCompletedThisMonth, 1);
    expect(stats.booksAddedThisMonth, 3);
    expect(stats.pagesRead, 220);
    expect(stats.averageReadingProgress, closeTo(50, 0.001));
    expect(stats.totalMinutesRead, 120);
    expect(stats.daysWithActivity, 2);
    expect(stats.currentStreakDays, 2);
    expect(stats.bestDay, yesterday);
    expect(stats.bestDayMinutes, 90);
    expect(stats.topRatedBooks.first.title, 'Book Two');
    expect(stats.topAuthors.first.author, 'Author A');
    expect(stats.topAuthors.first.minutes, 70);
    expect(stats.topBooksByTime.first.title, 'Book One');
    expect(stats.topBooksByTime.first.minutes, 70);
  });

  test('current streak counts consecutive days ending today', () {
    final today = DateTime(2026, 5, 21);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final fourDaysAgo = today.subtract(const Duration(days: 4));

    final stats = calculateStats(const [], [
      _session('s1', 'book-1', fourDaysAgo, 10),
      _session('s2', 'book-1', twoDaysAgo, 20),
      _session('s3', 'book-1', yesterday, 30),
      _session('s4', 'book-1', today, 40),
    ], today: today);

    expect(stats.currentStreakDays, 3);
  });

  test('current streak remains active when last active day is yesterday', () {
    final today = DateTime(2026, 5, 21);
    final yesterday = today.subtract(const Duration(days: 1));

    final stats = calculateStats(const [], [
      _session('s1', 'book-1', yesterday, 30),
    ], today: today);

    expect(stats.currentStreakDays, 1);
  });

  test('completed books count total pages before current page', () {
    final today = DateTime(2026, 5, 21);
    final books = [
      Book(
        id: '1',
        title: 'Completed Book',
        createdAt: today,
        status: BookStatus.completed,
        totalPages: 300,
        currentPage: 120,
      ),
      Book(
        id: '2',
        title: 'Reading Book',
        createdAt: today,
        status: BookStatus.reading,
        totalPages: 400,
        currentPage: 80,
      ),
    ];

    final stats = calculateStats(books, const [], today: today);

    expect(stats.pagesRead, 380);
  });

  test('top authors counts unique books instead of sessions', () {
    final today = DateTime(2026, 5, 21);
    final books = [
      Book(id: '1', title: 'One', author: 'Author A', createdAt: today),
      Book(id: '2', title: 'Two', author: 'Author A', createdAt: today),
    ];
    final sessions = [
      _session('s1', '1', today, 10),
      _session('s2', '1', today, 20),
      _session('s3', '2', today, 30),
    ];

    final stats = calculateStats(books, sessions, today: today);

    expect(stats.topAuthors.single.author, 'Author A');
    expect(stats.topAuthors.single.minutes, 60);
    expect(stats.topAuthors.single.bookCount, 2);
  });

  test('top authors is empty without sessions', () {
    final today = DateTime(2026, 5, 21);
    final books = [
      Book(
        id: '1',
        title: 'Book',
        author: 'Author A',
        createdAt: today,
        totalPages: 100,
      ),
    ];

    final stats = calculateStats(books, const [], today: today);

    expect(stats.topAuthors, isEmpty);
  });

  test('empty input returns zero stats', () {
    final stats = calculateStats(
      const [],
      const [],
      today: DateTime(2026, 5, 21),
    );

    expect(stats.totalBooks, 0);
    expect(stats.totalMinutesRead, 0);
    expect(stats.daysWithActivity, 0);
    expect(stats.currentStreakDays, 0);
    expect(stats.topRatedBooks, isEmpty);
    expect(stats.topAuthors, isEmpty);
    expect(stats.topBooksByTime, isEmpty);
  });

  test('statistics summary calculates current and best reading streaks', () {
    final today = DateTime(2026, 5, 21);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final fourDaysAgo = today.subtract(const Duration(days: 4));
    final fiveDaysAgo = today.subtract(const Duration(days: 5));

    final summary = const StatisticsCalculator().calculateFromBooks(
      const [],
      sessions: [
        _session('s1', 'book-1', fiveDaysAgo, 10),
        _session('s2', 'book-1', fourDaysAgo, 20),
        _session('s3', 'book-1', twoDaysAgo, 30),
        _session('s4', 'book-1', yesterday, 40),
      ],
      now: today,
    );

    expect(summary.currentStreakDays, 2);
    expect(summary.bestStreakDays, 2);
  });

  test(
    'statistics summary current streak is zero without today or yesterday',
    () {
      final today = DateTime(2026, 5, 21);
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      final summary = const StatisticsCalculator().calculateFromBooks(
        const [],
        sessions: [_session('s1', 'book-1', twoDaysAgo, 10)],
        now: today,
      );

      expect(summary.currentStreakDays, 0);
      expect(summary.bestStreakDays, 1);
    },
  );
}

ReadingSession _session(String id, String bookId, DateTime date, int minutes) {
  return ReadingSession(
    id: id,
    bookId: bookId,
    date: date,
    minutes: minutes,
    createdAt: date,
  );
}
