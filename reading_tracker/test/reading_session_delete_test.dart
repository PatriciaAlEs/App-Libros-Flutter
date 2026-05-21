import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/books/data/repositories/book_repository_provider.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/books/domain/repositories/book_repository.dart';
import 'package:reading_tracker/features/reading_sessions/data/repositories/reading_session_repository_provider.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/reading_sessions/domain/repositories/reading_session_repository.dart';
import 'package:reading_tracker/features/reading_sessions/presentation/screens/day_detail_screen.dart';

void main() {
  testWidgets('canceling delete keeps the session', (tester) async {
    final repository = _FakeReadingSessionRepository(
      sessionsForDay: [_session()],
    );

    await _pumpDayDetail(tester, repository);

    await tester.tap(find.byTooltip('Eliminar rato de lectura'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repository.deletedSessionId, isNull);
    expect(find.text('Current Book'), findsOneWidget);
  });

  testWidgets('confirming delete removes the selected session', (tester) async {
    final repository = _FakeReadingSessionRepository(
      sessionsForDay: [_session()],
    );

    await _pumpDayDetail(tester, repository);

    await tester.tap(find.byTooltip('Eliminar rato de lectura'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(repository.deletedSessionId, 'session-1');
  });
}

Future<void> _pumpDayDetail(
  WidgetTester tester,
  _FakeReadingSessionRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bookRepositoryProvider.overrideWithValue(
          _FakeBookRepository([
            _book('book-1', 'Current Book', BookStatus.reading),
          ]),
        ),
        readingSessionRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(home: DayDetailScreen(day: DateTime(2026, 5, 21))),
    ),
  );
  await tester.pumpAndSettle();
}

ReadingSession _session() {
  final day = DateTime(2026, 5, 21);
  return ReadingSession(
    id: 'session-1',
    bookId: 'book-1',
    date: day,
    minutes: 30,
    createdAt: day,
  );
}

Book _book(String id, String title, BookStatus status) {
  return Book(id: id, title: title, status: status, createdAt: DateTime(2026));
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
  _FakeReadingSessionRepository({this.sessionsForDay = const []});

  final List<ReadingSession> sessionsForDay;
  String? deletedSessionId;

  @override
  Future<void> addSession(ReadingSession session) async {}

  @override
  Future<void> deleteSession(String id) async {
    deletedSessionId = id;
  }

  @override
  Future<List<ReadingSession>> getSessionsForDay(DateTime day) async {
    return sessionsForDay;
  }

  @override
  Future<List<ReadingSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    return sessionsForDay;
  }

  @override
  Future<void> updateSession(ReadingSession session) async {}

  @override
  Stream<List<ReadingSession>> watchSessionsInRange(
    DateTime start,
    DateTime end,
  ) {
    return Stream.value(sessionsForDay);
  }
}
