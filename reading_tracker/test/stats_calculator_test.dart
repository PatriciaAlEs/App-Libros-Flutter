import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/stats/domain/stats_calculator.dart';

void main() {
  test('calculateStats computes summary and streak correctly', () {
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
}
