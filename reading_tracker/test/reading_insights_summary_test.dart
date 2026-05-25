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
      expect(summary.hasAnyInsight, isFalse);
    },
  );
}

ReadingSession _session(
  String id,
  String bookId,
  DateTime date, {
  required int pagesRead,
  int minutes = 0,
}) {
  return ReadingSession(
    id: id,
    bookId: bookId,
    date: date,
    minutes: minutes,
    pagesRead: pagesRead,
    createdAt: date,
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
