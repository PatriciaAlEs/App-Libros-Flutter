import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/core/preferences/reader_profile_controller.dart';
import 'package:reading_tracker/features/books/data/repositories/book_repository_provider.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/repositories/book_repository.dart';
import 'package:reading_tracker/features/coach/domain/models/reader_context.dart';
import 'package:reading_tracker/features/coach/domain/providers/reader_context_provider.dart';
import 'package:reading_tracker/features/coach/domain/services/reader_context_builder.dart';
import 'package:reading_tracker/features/reading_sessions/data/repositories/reading_session_repository_provider.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/reading_sessions/domain/repositories/reading_session_repository.dart';
import 'package:reading_tracker/features/stats/data/repositories/annual_reading_goal_repository_provider.dart';
import 'package:reading_tracker/features/stats/domain/repositories/annual_reading_goal_repository.dart';

void main() {
  group('readerContextProvider', () {
    test('resolves a ReaderContext from local providers', () async {
      final container = ProviderContainer(
        overrides: [
          bookRepositoryProvider.overrideWithValue(
            _FakeBookRepository([_book('book-1')]),
          ),
          readingSessionRepositoryProvider.overrideWithValue(
            _FakeReadingSessionRepository([_session('session-1', 'book-1')]),
          ),
          annualReadingGoalRepositoryProvider.overrideWithValue(
            const _FakeAnnualReadingGoalRepository(12),
          ),
          readerProfileControllerProvider.overrideWith(
            (ref) => _FakeReaderProfileController(
              const ReaderProfile(name: 'Patri'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final context = await container.read(readerContextProvider.future);

      expect(context, isA<ReaderContext>());
      expect(context.library.allBooks.single.id, 'book-1');
      expect(context.activity.readingSessions.single.id, 'session-1');
      expect(context.annualReadingGoal, 12);
      expect(context.readerProfile?.name, 'Patri');
    });

    test('can override the builder in tests', () async {
      final expectedContext = ReaderContext(
        metadata: ReaderContextMetadata(generatedAt: DateTime(2026, 7, 9)),
        library: ReaderLibraryContext(
          allBooks: const [],
          currentBooks: const [],
          completedBooks: const [],
          pendingBooks: const [],
          abandonedBooks: const [],
        ),
        activity: ReaderActivityContext(readingSessions: const []),
      );
      final builder = _FakeReaderContextBuilder(expectedContext);
      final container = ProviderContainer(
        overrides: [readerContextBuilderProvider.overrideWithValue(builder)],
      );
      addTearDown(container.dispose);

      final context = await container.read(readerContextProvider.future);

      expect(context, same(expectedContext));
      expect(builder.buildCount, 1);
    });

    test('reader context source does not introduce forbidden integrations', () {
      final source = [
        File('lib/features/coach/domain/providers/reader_context_provider.dart'),
        File('lib/features/coach/domain/services/reader_context_builder.dart'),
        File('lib/features/coach/domain/services/reader_context_builder_impl.dart'),
      ].map((file) => file.readAsStringSync()).join();

      for (final forbiddenPattern in [
        RegExp('OpenAI'),
        RegExp('LLM'),
        RegExp('prompt'),
        RegExp('chat'),
        RegExp('ToolManager'),
        RegExp('recommendation'),
        RegExp('remote'),
        RegExp(r'\bsync\b'),
      ]) {
        expect(forbiddenPattern.hasMatch(source), isFalse);
      }
    });
  });
}

Book _book(String id) {
  return Book(id: id, title: 'Book $id', createdAt: DateTime(2026, 7, 1));
}

ReadingSession _session(String id, String bookId) {
  return ReadingSession(
    id: id,
    bookId: bookId,
    date: DateTime(2026, 7, 8),
    minutes: 30,
    createdAt: DateTime(2026, 7, 8, 20),
  );
}

class _FakeReaderContextBuilder implements ReaderContextBuilder {
  _FakeReaderContextBuilder(this.context);

  final ReaderContext context;
  int buildCount = 0;

  @override
  Future<ReaderContext> build() async {
    buildCount++;
    return context;
  }
}

class _FakeReaderProfileController extends ReaderProfileController {
  _FakeReaderProfileController(ReaderProfile profile) : super() {
    state = profile;
  }
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

class _FakeAnnualReadingGoalRepository implements AnnualReadingGoalRepository {
  const _FakeAnnualReadingGoalRepository(this.goal);

  final int goal;

  @override
  Future<int?> getAnnualReadingGoal() async => goal;

  @override
  Future<void> saveAnnualReadingGoal(int goal) async {}
}
