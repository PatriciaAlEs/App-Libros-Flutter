import '../usecases/sync_pending_books_to_supabase.dart';
import '../usecases/sync_pending_reading_sessions_to_supabase.dart';
import '../usecases/sync_pending_reader_profile_to_supabase.dart';

class SyncOrchestrationResult {
  const SyncOrchestrationResult({
    required this.books,
    required this.readingSessions,
    required this.readerProfile,
  });

  final SyncPendingBooksResult books;
  final SyncPendingReadingSessionsResult readingSessions;
  final SyncPendingReaderProfileResult readerProfile;

  int get synced =>
      books.synced + readingSessions.synced + readerProfile.synced;
  int get failed =>
      books.failed + readingSessions.failed + readerProfile.failed;
  int get ignored =>
      books.ignored + readingSessions.ignored + readerProfile.ignored;
}

class SyncOrchestrator {
  const SyncOrchestrator({
    required SyncPendingBooksToSupabase syncBooks,
    required SyncPendingReadingSessionsToSupabase syncReadingSessions,
    required SyncPendingReaderProfileToSupabase syncReaderProfile,
  }) : _syncBooks = syncBooks,
       _syncReadingSessions = syncReadingSessions,
       _syncReaderProfile = syncReaderProfile;

  final SyncPendingBooksToSupabase _syncBooks;
  final SyncPendingReadingSessionsToSupabase _syncReadingSessions;
  final SyncPendingReaderProfileToSupabase _syncReaderProfile;

  Future<SyncOrchestrationResult> runManualSync({
    required String userId,
  }) async {
    final books = await _syncBooks(userId: userId);
    final readingSessions = await _syncReadingSessions(userId: userId);
    final readerProfile = await _syncReaderProfile(userId: userId);
    return SyncOrchestrationResult(
      books: books,
      readingSessions: readingSessions,
      readerProfile: readerProfile,
    );
  }
}
