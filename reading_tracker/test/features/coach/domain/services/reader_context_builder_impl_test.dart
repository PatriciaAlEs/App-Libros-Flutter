import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/core/preferences/reader_profile_controller.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/books/domain/repositories/book_repository.dart';
import 'package:reading_tracker/features/coach/domain/services/reader_context_builder_impl.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/reading_sessions/domain/repositories/reading_session_repository.dart';
import 'package:reading_tracker/features/stats/domain/repositories/annual_reading_goal_repository.dart';

void main() {
  group('ReaderContextBuilderImpl', () {
    test('builds an empty context for empty user state', () async {
      final builder = ReaderContextBuilderImpl(
        bookRepository: _FakeBookRepository(),
        readingSessionRepository: _FakeReadingSessionRepository(),
        now: () => DateTime(2026, 7, 9, 10),
      );

      final context = await builder.build();

      expect(context.metadata.generatedAt, DateTime(2026, 7, 9, 10));
      expect(context.library.allBooks, isEmpty);
      expect(context.library.currentBooks, isEmpty);
      expect(context.library.completedBooks, isEmpty);
      expect(context.library.pendingBooks, isEmpty);
      expect(context.library.abandonedBooks, isEmpty);
      expect(context.activity.readingSessions, isEmpty);
      expect(context.annualReadingGoal, isNull);
      expect(context.readerProfile, isNull);
    });

    test('builds context for user with books but no sessions', () async {
      final profile = const ReaderProfile(name: 'Patri');
      final builder = ReaderContextBuilderImpl(
        bookRepository: _FakeBookRepository(books: [_book('book-1')]),
        readingSessionRepository: _FakeReadingSessionRepository(),
        annualReadingGoalRepository: _FakeAnnualReadingGoalRepository(24),
        readerProfileLoader: () async => profile,
        now: () => DateTime(2026, 7, 9, 10),
      );

      final context = await builder.build();

      expect(context.library.allBooks.single.title, 'Book book-1');
      expect(context.activity.readingSessions, isEmpty);
      expect(context.annualReadingGoal, 24);
      expect(context.readerProfile, same(profile));
    });

    test('separates library books by semantic status', () async {
      final currentBook = _book('current', status: BookStatus.reading);
      final completedBook = _book('completed', status: BookStatus.completed);
      final pendingBook = _book('pending', status: BookStatus.pending);
      final abandonedBook = _book('abandoned', status: BookStatus.abandoned);
      final session = _session('session-1', currentBook.id);
      final builder = ReaderContextBuilderImpl(
        bookRepository: _FakeBookRepository(
          books: [currentBook, completedBook, pendingBook, abandonedBook],
        ),
        readingSessionRepository: _FakeReadingSessionRepository(
          sessions: [session],
        ),
        now: () => DateTime(2026, 7, 9, 10),
      );

      final context = await builder.build();

      expect(context.library.allBooks, [
        currentBook,
        completedBook,
        pendingBook,
        abandonedBook,
      ]);
      expect(context.library.currentBooks, [currentBook]);
      expect(context.library.completedBooks, [completedBook]);
      expect(context.library.pendingBooks, [pendingBook]);
      expect(context.library.abandonedBooks, [abandonedBook]);
      expect(context.activity.readingSessions, [session]);
    });

    test('generatedAt is set from the clock', () async {
      final generatedAt = DateTime(2026, 7, 9, 18, 30);
      final builder = ReaderContextBuilderImpl(
        bookRepository: _FakeBookRepository(),
        readingSessionRepository: _FakeReadingSessionRepository(),
        now: () => generatedAt,
      );

      final context = await builder.build();

      expect(context.metadata.generatedAt, generatedAt);
    });

    test('does not mutate source data', () async {
      final books = [_book('book-1', status: BookStatus.reading)];
      final sessions = [_session('session-1', 'book-1')];
      final builder = ReaderContextBuilderImpl(
        bookRepository: _FakeBookRepository(books: books),
        readingSessionRepository: _FakeReadingSessionRepository(
          sessions: sessions,
        ),
        now: () => DateTime(2026, 7, 9, 10),
      );

      final context = await builder.build();
      books.add(_book('book-2', status: BookStatus.completed));
      sessions.add(_session('session-2', 'book-2'));

      expect(context.library.allBooks.map((book) => book.id), ['book-1']);
      expect(context.library.currentBooks.map((book) => book.id), ['book-1']);
      expect(context.library.completedBooks, isEmpty);
      expect(context.library.pendingBooks, isEmpty);
      expect(context.library.abandonedBooks, isEmpty);
      expect(context.activity.readingSessions.map((session) => session.id), [
        'session-1',
      ]);
      expect(
        () => context.library.allBooks.add(_book('book-3')),
        throwsUnsupportedError,
      );
      expect(
        () => context.library.currentBooks.add(_book('book-3')),
        throwsUnsupportedError,
      );
      expect(
        () => context.library.completedBooks.add(_book('book-3')),
        throwsUnsupportedError,
      );
      expect(
        () => context.library.pendingBooks.add(_book('book-3')),
        throwsUnsupportedError,
      );
      expect(
        () => context.library.abandonedBooks.add(_book('book-3')),
        throwsUnsupportedError,
      );
      expect(
        () => context.activity.readingSessions.add(
          _session('session-3', 'book-1'),
        ),
        throwsUnsupportedError,
      );
    });
  });
}

Book _book(String id, {BookStatus status = BookStatus.pending}) {
  return Book(
    id: id,
    title: 'Book $id',
    status: status,
    createdAt: DateTime(2026, 7, 1),
  );
}

ReadingSession _session(String id, String bookId) {
  return ReadingSession(
    id: id,
    bookId: bookId,
    date: DateTime(2026, 7, 8),
    minutes: 30,
    pagesRead: 12,
    createdAt: DateTime(2026, 7, 8, 20),
  );
}

class _FakeBookRepository implements BookRepository {
  const _FakeBookRepository({this.books = const []});

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
  const _FakeReadingSessionRepository({this.sessions = const []});

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
    return sessions
        .where(
          (session) =>
              session.date.year == day.year &&
              session.date.month == day.month &&
              session.date.day == day.day,
        )
        .toList();
  }

  @override
  Future<List<ReadingSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    return sessions
        .where(
          (session) =>
              !session.date.isBefore(start) && session.date.isBefore(end),
        )
        .toList();
  }

  @override
  Future<void> updateSession(ReadingSession session) async {}

  @override
  Stream<List<ReadingSession>> watchSessionsInRange(
    DateTime start,
    DateTime end,
  ) {
    return Stream.value(sessions);
  }
}

class _FakeAnnualReadingGoalRepository implements AnnualReadingGoalRepository {
  const _FakeAnnualReadingGoalRepository(this.goal);

  final int goal;

  @override
  Future<int?> getAnnualReadingGoal() async => goal;

  @override
  Future<void> saveAnnualReadingGoal(int goal) async {}
}
