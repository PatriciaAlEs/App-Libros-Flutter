import '../usecases/sync_pending_books_to_supabase.dart';
import '../usecases/sync_pending_reading_sessions_to_supabase.dart';

class SyncOrchestrationResult {
  const SyncOrchestrationResult({
    required this.books,
    required this.readingSessions,
  });

  final SyncPendingBooksResult books;
  final SyncPendingReadingSessionsResult readingSessions;

  int get synced => books.synced + readingSessions.synced;
  int get failed => books.failed + readingSessions.failed;
  int get ignored => books.ignored + readingSessions.ignored;
}

class SyncOrchestrator {
  const SyncOrchestrator({
    required SyncPendingBooksToSupabase syncBooks,
    required SyncPendingReadingSessionsToSupabase syncReadingSessions,
  }) : _syncBooks = syncBooks,
       _syncReadingSessions = syncReadingSessions;

  final SyncPendingBooksToSupabase _syncBooks;
  final SyncPendingReadingSessionsToSupabase _syncReadingSessions;

  Future<SyncOrchestrationResult> runManualSync({
    required String userId,
  }) async {
    final books = await _syncBooks(userId: userId);
    final readingSessions = await _syncReadingSessions(userId: userId);
    return SyncOrchestrationResult(
      books: books,
      readingSessions: readingSessions,
    );
  }
}
