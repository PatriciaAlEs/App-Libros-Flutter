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
import 'package:reading_tracker/features/reading_sessions/presentation/screens/session_form_screen.dart';

void main() {
  testWidgets('session form creates a session with a past initial date', (
    tester,
  ) async {
    final pastDate = DateTime(2026, 5, 18);
    final sessionRepository = _FakeReadingSessionRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(
            _FakeBookRepository([
              _book('book-1', 'Reading Book', BookStatus.reading),
            ]),
          ),
          readingSessionRepositoryProvider.overrideWithValue(sessionRepository),
        ],
        child: MaterialApp(home: _OpenFormHost(initialDate: pastDate)),
      ),
    );

    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();

    expect(find.text('18/5/2026'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '12');
    await tester.enterText(find.byType(TextFormField).at(1), '30');
    await tester.tap(find.text('Guardar tiempo de lectura'));
    await tester.pumpAndSettle();

    final added = sessionRepository.addedSession;
    expect(added, isNotNull);
    expect(added!.bookId, 'book-1');
    expect(added.date, pastDate);
    expect(added.pagesRead, 12);
    expect(added.minutes, 30);
  });

  testWidgets('session form updates an existing session', (tester) async {
    final createdAt = DateTime(2026, 5, 20, 10);
    final session = ReadingSession(
      id: 'session-1',
      bookId: 'book-1',
      date: DateTime(2026, 5, 21),
      minutes: 25,
      note: 'Original note',
      createdAt: createdAt,
    );
    final sessionRepository = _FakeReadingSessionRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(
            _FakeBookRepository([
              _book('book-1', 'Current Book', BookStatus.completed),
              _book('book-2', 'Reading Book', BookStatus.reading),
            ]),
          ),
          readingSessionRepositoryProvider.overrideWithValue(sessionRepository),
        ],
        child: MaterialApp(home: _OpenFormHost(session: session)),
      ),
    );

    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();

    expect(find.text('Editar rato de lectura'), findsOneWidget);
    expect(find.text('Current Book'), findsOneWidget);
    expect(find.text('Original note'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '45');
    await tester.enterText(find.byType(TextFormField).at(2), 'Updated note');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    final updated = sessionRepository.updatedSession;
    expect(updated, isNotNull);
    expect(updated!.id, session.id);
    expect(updated.bookId, session.bookId);
    expect(updated.date, session.date);
    expect(updated.minutes, 45);
    expect(updated.note, 'Updated note');
    expect(updated.createdAt, createdAt);
    expect(sessionRepository.addedSession, isNull);
  });

  testWidgets('day detail opens edit route with selected session', (
    tester,
  ) async {
    final day = DateTime(2026, 5, 21);
    final session = ReadingSession(
      id: 'session-1',
      bookId: 'book-1',
      date: day,
      minutes: 30,
      createdAt: day,
    );
    Object? editArguments;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(
            _FakeBookRepository([
              _book('book-1', 'Current Book', BookStatus.reading),
            ]),
          ),
          readingSessionRepositoryProvider.overrideWithValue(
            _FakeReadingSessionRepository(sessionsForDay: [session]),
          ),
        ],
        child: MaterialApp(
          home: DayDetailScreen(day: day),
          onGenerateRoute: (settings) {
            if (settings.name == '/session/edit') {
              editArguments = settings.arguments;
              return MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Edit route')),
              );
            }
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar rato de lectura'));
    await tester.pumpAndSettle();

    expect(editArguments, same(session));
    expect(find.text('Edit route'), findsOneWidget);
  });
}

class _OpenFormHost extends StatelessWidget {
  const _OpenFormHost({this.initialDate, this.session});

  final DateTime? initialDate;
  final ReadingSession? session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => SessionFormScreen(
                  initialDate: initialDate,
                  session: session,
                ),
              ),
            );
          },
          child: const Text('Open form'),
        ),
      ),
    );
  }
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
  ReadingSession? addedSession;
  ReadingSession? updatedSession;

  @override
  Future<void> addSession(ReadingSession session) async {
    addedSession = session;
  }

  @override
  Future<void> deleteSession(String id) async {}

  @override
  Future<List<ReadingSession>> getSessionsForDay(DateTime day) async {
    return sessionsForDay;
  }

  @override
  Future<List<ReadingSession>> getSessionsForBook(String bookId) async {
    return sessionsForDay.where((session) => session.bookId == bookId).toList();
  }

  @override
  Future<List<ReadingSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    return sessionsForDay;
  }

  @override
  Future<void> updateSession(ReadingSession session) async {
    updatedSession = session;
  }

  @override
  Stream<List<ReadingSession>> watchSessionsInRange(
    DateTime start,
    DateTime end,
  ) {
    return Stream.value(sessionsForDay);
  }
}
