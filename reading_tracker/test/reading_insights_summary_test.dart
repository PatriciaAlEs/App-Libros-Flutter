import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/books/domain/repositories/book_repository.dart';
import 'package:reading_tracker/features/insights/data/repositories/insights_repository_impl.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/reading_sessions/domain/repositories/reading_session_repository.dart';

void main() {
  test(
    'insights summary aggregates read pages by book, author and genre',
    () async {
      final today = DateTime(2026, 5, 25);
      final repository = InsightsRepositoryImpl(
        bookRepository: _FakeBookRepository([
          Book(
            id: 'book-1',
            title: 'Book One',
            author: 'Author A',
            genre: 'Fiction',
            createdAt: today,
          ),
          Book(
            id: 'book-2',
            title: 'Book Two',
            author: 'Author A',
            genre: 'Essay',
            createdAt: today,
          ),
          Book(
            id: 'book-3',
            title: 'Book Three',
            author: 'Author B',
            genre: 'Fiction',
            createdAt: today,
          ),
        ]),
        readingSessionRepository: _FakeReadingSessionRepository([
          _session('session-1', 'book-1', today, pagesRead: 40),
          _session('session-2', 'book-1', today, pagesRead: 20),
          _session('session-3', 'book-2', today, pagesRead: 50),
          _session('session-4', 'book-3', today, pagesRead: 80),
          _session('session-5', 'book-3', today, pagesRead: 0, minutes: 30),
        ]),
      );

      final summary = await repository.getSummary();

      expect(summary.mostReadBookTitle, 'Book Three');
      expect(summary.mostReadBookPages, 80);
      expect(summary.mostReadAuthor, 'Author A');
      expect(summary.mostReadAuthorPages, 110);
      expect(summary.favoriteGenre, 'Fiction');
      expect(summary.favoriteGenrePages, 140);
    },
  );

  test('insights summary is empty without sessions with pages read', () async {
    final today = DateTime(2026, 5, 25);
    final repository = InsightsRepositoryImpl(
      bookRepository: _FakeBookRepository([
        Book(
          id: 'book-1',
          title: 'Book One',
          author: 'Author A',
          genre: 'Fiction',
          createdAt: today,
        ),
      ]),
      readingSessionRepository: _FakeReadingSessionRepository([
        _session('session-1', 'book-1', today, pagesRead: 0, minutes: 30),
      ]),
    );

    final summary = await repository.getSummary();

    expect(summary.hasReadingActivity, isFalse);
    expect(summary.mostReadBookTitle, isNull);
    expect(summary.mostReadAuthor, isNull);
    expect(summary.favoriteGenre, isNull);
  });

  test('favorite genre remains empty when books have no genre', () async {
    final today = DateTime(2026, 5, 25);
    final repository = InsightsRepositoryImpl(
      bookRepository: _FakeBookRepository([
        Book(
          id: 'book-1',
          title: 'Book One',
          author: 'Author A',
          createdAt: today,
        ),
      ]),
      readingSessionRepository: _FakeReadingSessionRepository([
        _session('session-1', 'book-1', today, pagesRead: 25),
      ]),
    );

    final summary = await repository.getSummary();

    expect(summary.hasReadingActivity, isTrue);
    expect(summary.mostReadBookTitle, 'Book One');
    expect(summary.mostReadAuthor, 'Author A');
    expect(summary.favoriteGenre, isNull);
    expect(summary.favoriteGenrePages, 0);
  });

  test('insights summary calculates reading pace averages', () async {
    final today = DateTime(2026, 5, 25);
    final yesterday = today.subtract(const Duration(days: 1));
    final repository = InsightsRepositoryImpl(
      bookRepository: _FakeBookRepository([
        Book(id: 'book-1', title: 'Book One', createdAt: today),
      ]),
      readingSessionRepository: _FakeReadingSessionRepository([
        _session('session-1', 'book-1', today, pagesRead: 20, minutes: 30),
        _session('session-2', 'book-1', today, pagesRead: 40, minutes: 50),
        _session('session-3', 'book-1', yesterday, pagesRead: 0, minutes: 10),
      ]),
      now: () => today,
    );

    final summary = await repository.getSummary();

    expect(summary.averagePagesPerSession, 30);
    expect(summary.averageMinutesPerSession, 30);
    expect(summary.averagePagesPerActiveDay, 60);
  });

  test(
    'insights summary predicts finish date for current reading book',
    () async {
      final today = DateTime(2026, 5, 25);
      final yesterday = today.subtract(const Duration(days: 1));
      final repository = InsightsRepositoryImpl(
        bookRepository: _FakeBookRepository([
          Book(
            id: 'book-1',
            title: 'Current Book',
            createdAt: today,
            updatedAt: today,
            status: BookStatus.reading,
            totalPages: 200,
            currentPage: 120,
          ),
        ]),
        readingSessionRepository: _FakeReadingSessionRepository([
          _session('session-1', 'book-1', today, pagesRead: 20, minutes: 30),
          _session(
            'session-2',
            'book-1',
            yesterday,
            pagesRead: 20,
            minutes: 30,
          ),
        ]),
        now: () => today,
      );

      final summary = await repository.getSummary();

      expect(summary.finishPredictionBookTitle, 'Current Book');
      expect(summary.finishPredictionRemainingPages, 80);
      expect(summary.finishPredictionRecentPagesPerDay, 20);
      expect(summary.finishPredictionDaysRemaining, 4);
      expect(summary.finishPredictionDate, DateTime(2026, 5, 29));
    },
  );

  test('insights summary calculates annual forecast', () async {
    final today = DateTime(2026, 5, 25);
    final repository = InsightsRepositoryImpl(
      bookRepository: _FakeBookRepository([
        Book(
          id: 'book-1',
          title: 'Completed One',
          createdAt: today,
          status: BookStatus.completed,
          completedDate: DateTime(2026, 2, 1),
        ),
        Book(
          id: 'book-2',
          title: 'Completed Two',
          createdAt: today,
          status: BookStatus.completed,
          completedDate: DateTime(2026, 5, 1),
        ),
        Book(
          id: 'book-3',
          title: 'Last Year',
          createdAt: today,
          status: BookStatus.completed,
          completedDate: DateTime(2025, 12, 31),
        ),
      ]),
      readingSessionRepository: const _FakeReadingSessionRepository([]),
      now: () => today,
    );

    final summary = await repository.getSummary();

    expect(summary.completedBooksThisYear, 2);
    expect(summary.annualBooksForecast, 5);
  });

  test(
    'insights summary exposes empty states for pace and predictions',
    () async {
      final today = DateTime(2026, 5, 25);
      final repository = InsightsRepositoryImpl(
        bookRepository: _FakeBookRepository([
          Book(
            id: 'book-1',
            title: 'Pending Book',
            createdAt: today,
            status: BookStatus.pending,
          ),
        ]),
        readingSessionRepository: const _FakeReadingSessionRepository([]),
        now: () => today,
      );

      final summary = await repository.getSummary();

      expect(summary.averagePagesPerSession, isNull);
      expect(summary.averageMinutesPerSession, isNull);
      expect(summary.averagePagesPerActiveDay, isNull);
      expect(summary.hasFinishPrediction, isFalse);
      expect(summary.annualBooksForecast, isNull);
      expect(summary.topRatedBookTitle, isNull);
      expect(summary.longestBookTitle, isNull);
      expect(summary.mostTimeBookTitle, isNull);
      expect(summary.mostSessionsBookTitle, isNull);
      expect(summary.topAuthors, isEmpty);
      expect(summary.topGenres, isEmpty);
      expect(summary.topBooks, isEmpty);
      expect(summary.bestStreakDays, 0);
      expect(summary.hasAnyInsight, isFalse);
    },
  );

  test('insights summary finds top reads of the year', () async {
    final today = DateTime(2026, 5, 25);
    final repository = InsightsRepositoryImpl(
      bookRepository: _FakeBookRepository([
        Book(
          id: 'book-1',
          title: 'Best Rated',
          author: 'Favorite Author',
          coverUrl: 'https://example.com/best-rated.jpg',
          notes: 'Una lectura inolvidable.',
          createdAt: today,
          status: BookStatus.completed,
          totalPages: 200,
          rating: 5,
          completedDate: DateTime(2026, 3, 1),
        ),
        Book(
          id: 'book-2',
          title: 'Longest Book',
          coverUrl: 'https://example.com/longest.jpg',
          createdAt: today,
          status: BookStatus.completed,
          totalPages: 450,
          rating: 4,
          completedDate: DateTime(2026, 4, 1),
        ),
        Book(
          id: 'book-3',
          title: 'Last Year Favorite',
          createdAt: today,
          status: BookStatus.completed,
          totalPages: 900,
          rating: 5,
          completedDate: DateTime(2025, 12, 1),
        ),
        Book(
          id: 'book-4',
          title: 'Most Time',
          createdAt: today,
          status: BookStatus.reading,
        ),
        Book(
          id: 'book-5',
          title: 'Most Sessions',
          createdAt: today,
          status: BookStatus.reading,
        ),
      ]),
      readingSessionRepository: _FakeReadingSessionRepository([
        _session('session-1', 'book-4', today, pagesRead: 20, minutes: 90),
        _session('session-2', 'book-4', today, pagesRead: 10, minutes: 60),
        _session('session-3', 'book-5', today, pagesRead: 5, minutes: 10),
        _session('session-4', 'book-5', today, pagesRead: 5, minutes: 10),
        _session('session-5', 'book-5', today, pagesRead: 5, minutes: 10),
        _session(
          'session-6',
          'book-3',
          DateTime(2025, 12, 1),
          pagesRead: 50,
          minutes: 500,
        ),
      ]),
      now: () => today,
    );

    final summary = await repository.getSummary();

    expect(summary.topRatedBookTitle, 'Best Rated');
    expect(summary.topRatedBookRating, 5);
    expect(summary.topRatedBooks.map((book) => book.title), [
      'Best Rated',
      'Longest Book',
    ]);
    expect(summary.topRatedBooks.first.author, 'Favorite Author');
    expect(
      summary.topRatedBooks.first.coverUrl,
      'https://example.com/best-rated.jpg',
    );
    expect(summary.topRatedBooks.first.review, 'Una lectura inolvidable.');
    expect(summary.longestBookTitle, 'Longest Book');
    expect(summary.longestBookPages, 450);
    expect(summary.longestBookCoverUrl, 'https://example.com/longest.jpg');
    expect(summary.shortestBookTitle, 'Best Rated');
    expect(summary.shortestBookPages, 200);
    expect(summary.shortestBookCoverUrl, 'https://example.com/best-rated.jpg');
    expect(summary.mostTimeBookTitle, 'Most Time');
    expect(summary.mostTimeBookMinutes, 150);
    expect(summary.mostSessionsBookTitle, 'Most Sessions');
    expect(summary.mostSessionsCount, 3);
  });

  test('insights summary calculates premium profile curiosities', () async {
    final today = DateTime(2026, 5, 25);
    final repository = InsightsRepositoryImpl(
      bookRepository: _FakeBookRepository([
        Book(
          id: 'book-1',
          title: 'Five Stars',
          author: 'Author A',
          genre: 'Essay',
          createdAt: today,
          status: BookStatus.completed,
          rating: 5,
          totalPages: 250,
          completedDate: DateTime(2026, 3, 1),
        ),
        Book(
          id: 'book-2',
          title: 'Also Five Stars',
          author: 'Author B',
          genre: 'Fantasy',
          createdAt: today,
          status: BookStatus.completed,
          rating: 5,
          totalPages: 320,
          completedDate: DateTime(2026, 4, 1),
        ),
        Book(
          id: 'book-3',
          title: 'Four Stars',
          author: 'Author A',
          genre: 'Essay',
          createdAt: today,
          status: BookStatus.completed,
          rating: 4,
          totalPages: 180,
          completedDate: DateTime(2026, 5, 1),
        ),
        Book(
          id: 'book-4',
          title: 'Old Favorite',
          createdAt: today,
          status: BookStatus.completed,
          rating: 5,
          totalPages: 900,
          completedDate: DateTime(2025, 5, 1),
        ),
      ]),
      readingSessionRepository: _FakeReadingSessionRepository([
        _session(
          'session-1',
          'book-1',
          DateTime(2026, 4, 10),
          pagesRead: 40,
          minutes: 30,
          createdAt: DateTime(2026, 4, 10, 20),
        ),
        _session(
          'session-2',
          'book-2',
          DateTime(2026, 4, 10),
          pagesRead: 50,
          minutes: 20,
          createdAt: DateTime(2026, 4, 10, 21),
        ),
        _session(
          'session-3',
          'book-3',
          DateTime(2026, 4, 11),
          pagesRead: 30,
          minutes: 15,
          createdAt: DateTime(2026, 4, 11, 9),
        ),
        _session(
          'session-4',
          'book-1',
          DateTime(2026, 5, 2),
          pagesRead: 60,
          minutes: 60,
          createdAt: DateTime(2026, 5, 2, 20),
        ),
      ]),
      now: () => today,
    );

    final summary = await repository.getSummary();

    expect(summary.topRatedBooks.map((book) => book.title), [
      'Also Five Stars',
      'Five Stars',
      'Four Stars',
    ]);
    expect(summary.mostActiveMonth, DateTime(2026, 4));
    expect(summary.mostActiveMonthPages, 120);
    expect(summary.mostActiveMonthMinutes, 65);
    expect(summary.usualReadingTimeSlot, 'Noche');
    expect(summary.usualReadingTimeSlotSessions, 3);
    expect(summary.mostActiveDay, DateTime(2026, 4, 10));
    expect(summary.mostActiveDayPages, 90);
    expect(summary.mostActiveDayMinutes, 50);
  });

  test('insights summary calculates personal rankings top three', () async {
    final today = DateTime(2026, 5, 25);
    final repository = InsightsRepositoryImpl(
      bookRepository: _FakeBookRepository([
        Book(
          id: 'book-1',
          title: 'Alpha',
          author: 'Author A',
          genre: 'Fantasy',
          createdAt: today,
        ),
        Book(
          id: 'book-2',
          title: 'Beta',
          author: 'Author B',
          genre: 'Essay',
          createdAt: today,
        ),
        Book(
          id: 'book-3',
          title: 'Gamma',
          author: 'Author A',
          genre: 'Fantasy',
          createdAt: today,
        ),
        Book(
          id: 'book-4',
          title: 'Delta',
          author: 'Author C',
          genre: 'Memoir',
          createdAt: today,
        ),
      ]),
      readingSessionRepository: _FakeReadingSessionRepository([
        _session('session-1', 'book-1', today, pagesRead: 40),
        _session('session-2', 'book-2', today, pagesRead: 80),
        _session('session-3', 'book-3', today, pagesRead: 70),
        _session('session-4', 'book-4', today, pagesRead: 20),
      ]),
      now: () => today,
    );

    final summary = await repository.getSummary();

    expect(summary.topAuthors.map((item) => item.label), [
      'Author A',
      'Author B',
      'Author C',
    ]);
    expect(summary.topAuthors.map((item) => item.value), [110, 80, 20]);
    expect(summary.topGenres.map((item) => item.label), [
      'Fantasy',
      'Essay',
      'Memoir',
    ]);
    expect(summary.topGenres.map((item) => item.value), [110, 80, 20]);
    expect(summary.topBooks.map((item) => item.label), [
      'Beta',
      'Gamma',
      'Alpha',
    ]);
    expect(summary.topBooks.map((item) => item.value), [80, 70, 40]);
  });

  test('insights summary reuses statistics best streak', () async {
    final today = DateTime(2026, 5, 25);
    final repository = InsightsRepositoryImpl(
      bookRepository: _FakeBookRepository([
        Book(id: 'book-1', title: 'Book One', createdAt: today),
      ]),
      readingSessionRepository: _FakeReadingSessionRepository([
        _session('session-1', 'book-1', DateTime(2026, 5, 20), pagesRead: 10),
        _session('session-2', 'book-1', DateTime(2026, 5, 21), pagesRead: 10),
        _session('session-3', 'book-1', DateTime(2026, 5, 23), pagesRead: 10),
      ]),
      now: () => today,
    );

    final summary = await repository.getSummary();

    expect(summary.bestStreakDays, 2);
  });
}

ReadingSession _session(
  String id,
  String bookId,
  DateTime date, {
  required int pagesRead,
  int minutes = 0,
  DateTime? createdAt,
}) {
  return ReadingSession(
    id: id,
    bookId: bookId,
    date: date,
    minutes: minutes,
    pagesRead: pagesRead,
    createdAt: createdAt ?? date,
  );
}

class _FakeBookRepository implements BookRepository {
  const _FakeBookRepository(this.books);

  final List<Book> books;

  @override
  Future<void> addBook(Book book) async {}

  @override
  Future<void> deleteBook(String id) async {}

  @override
  Future<List<Book>> getAllBooks() async => books;

  @override
  Future<Book?> getBookById(String id) async {
    for (final book in books) {
      if (book.id == id) return book;
    }
    return null;
  }

  @override
  Future<void> updateBook(Book book) async {}

  @override
  Stream<List<Book>> watchBooks() => Stream.value(books);
}

class _FakeReadingSessionRepository implements ReadingSessionRepository {
  const _FakeReadingSessionRepository(this.sessions);

  final List<ReadingSession> sessions;

  @override
  Future<void> addSession(ReadingSession session) async {}

  @override
  Future<void> deleteSession(String id) async {}

  @override
  Future<List<ReadingSession>> getSessionsForBook(String bookId) async {
    return sessions.where((session) => session.bookId == bookId).toList();
  }

  @override
  Future<List<ReadingSession>> getSessionsForDay(DateTime day) async {
    return sessions.where((session) {
      return session.date.year == day.year &&
          session.date.month == day.month &&
          session.date.day == day.day;
    }).toList();
  }

  @override
  Future<List<ReadingSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    return sessions.where((session) {
      return !session.date.isBefore(start) && session.date.isBefore(end);
    }).toList();
  }

  @override
  Future<void> updateSession(ReadingSession session) async {}

  @override
  Stream<List<ReadingSession>> watchSessionsInRange(
    DateTime start,
    DateTime end,
  ) {
    return Stream.fromFuture(getSessionsInRange(start, end));
  }
}
