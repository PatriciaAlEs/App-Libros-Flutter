import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/auth/domain/app_user.dart';
import 'package:reading_tracker/features/auth/domain/entities/account_migration_preparation.dart';
import 'package:reading_tracker/features/auth/domain/usecases/prepare_account_migration.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/repositories/book_repository.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/reading_sessions/domain/repositories/reading_session_repository.dart';
import 'package:reading_tracker/features/stats/domain/repositories/annual_reading_goal_repository.dart';

void main() {
  group('PrepareAccountMigration', () {
    test('returns unauthenticated when there is no user', () async {
      final useCase = PrepareAccountMigration(
        bookRepository: _FakeBookRepository(),
        readingSessionRepository: _FakeReadingSessionRepository(),
        annualReadingGoalRepository: _FakeAnnualReadingGoalRepository(),
      );

      final result = await useCase(user: null, hasReaderProfileData: false);

      expect(result.status, AccountMigrationPreparationStatus.unauthenticated);
      expect(result.userId, isNull);
      expect(result.summary.hasLocalData, isFalse);
    });

    test(
      'returns noLocalData for authenticated users without local data',
      () async {
        final useCase = PrepareAccountMigration(
          bookRepository: _FakeBookRepository(),
          readingSessionRepository: _FakeReadingSessionRepository(),
          annualReadingGoalRepository: _FakeAnnualReadingGoalRepository(),
        );

        final result = await useCase(
          user: const AppUser(id: 'user-1', email: 'reader@example.com'),
          hasReaderProfileData: false,
        );

        expect(result.status, AccountMigrationPreparationStatus.noLocalData);
        expect(result.userId, 'user-1');
        expect(result.summary.hasLocalData, isFalse);
      },
    );

    test('prepares local data summary for future sync', () async {
      final now = DateTime(2026, 6, 27);
      final book = Book(id: 'book-1', title: 'Book', createdAt: now);
      final session = ReadingSession(
        id: 'session-1',
        bookId: book.id,
        date: now,
        minutes: 20,
        pagesRead: 12,
        createdAt: now,
      );
      final useCase = PrepareAccountMigration(
        bookRepository: _FakeBookRepository(books: [book]),
        readingSessionRepository: _FakeReadingSessionRepository(
          sessionsByBook: {
            book.id: [session],
          },
        ),
        annualReadingGoalRepository: _FakeAnnualReadingGoalRepository(goal: 24),
      );

      final result = await useCase(
        user: const AppUser(id: 'user-1', email: 'reader@example.com'),
        hasReaderProfileData: true,
      );

      expect(
        result.status,
        AccountMigrationPreparationStatus.readyForFutureSync,
      );
      expect(result.isReadyForFutureSync, isTrue);
      expect(result.userId, 'user-1');
      expect(result.summary.bookCount, 1);
      expect(result.summary.readingSessionCount, 1);
      expect(result.summary.hasAnnualGoal, isTrue);
      expect(result.summary.hasReaderProfile, isTrue);
      expect(
        result.summary.scopes,
        containsAll([
          AccountMigrationDataScope.library,
          AccountMigrationDataScope.readingProgress,
          AccountMigrationDataScope.readingSessions,
          AccountMigrationDataScope.statistics,
          AccountMigrationDataScope.preferences,
        ]),
      );
    });
  });
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
    return books.where((book) => book.id == id).firstOrNull;
  }

  @override
  Future<void> updateBook(Book book) async {}

  @override
  Stream<List<Book>> watchBooks() => Stream.value(books);
}

class _FakeReadingSessionRepository implements ReadingSessionRepository {
  const _FakeReadingSessionRepository({this.sessionsByBook = const {}});

  final Map<String, List<ReadingSession>> sessionsByBook;

  @override
  Future<void> addSession(ReadingSession session) async {}

  @override
  Future<void> deleteSession(String id) async {}

  @override
  Future<List<ReadingSession>> getSessionsForBook(String bookId) async {
    return sessionsByBook[bookId] ?? const [];
  }

  @override
  Future<List<ReadingSession>> getSessionsForDay(DateTime day) async {
    return const [];
  }

  @override
  Future<List<ReadingSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    return const [];
  }

  @override
  Future<void> updateSession(ReadingSession session) async {}

  @override
  Stream<List<ReadingSession>> watchSessionsInRange(
    DateTime start,
    DateTime end,
  ) {
    return const Stream.empty();
  }
}

class _FakeAnnualReadingGoalRepository implements AnnualReadingGoalRepository {
  const _FakeAnnualReadingGoalRepository({this.goal});

  final int? goal;

  @override
  Future<int?> getAnnualReadingGoal() async => goal;

  @override
  Future<void> saveAnnualReadingGoal(int goal) async {}
}
