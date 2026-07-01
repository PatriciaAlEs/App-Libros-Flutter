import '../usecases/sync_pending_books_to_supabase.dart';

class SyncOrchestrationResult {
  const SyncOrchestrationResult({required this.books});

  final SyncPendingBooksResult books;

  int get synced => books.synced;
  int get failed => books.failed;
  int get ignored => books.ignored;
}

class SyncOrchestrator {
  const SyncOrchestrator({required SyncPendingBooksToSupabase syncBooks})
    : _syncBooks = syncBooks;

  final SyncPendingBooksToSupabase _syncBooks;

  Future<SyncOrchestrationResult> runManualSync({
    required String userId,
  }) async {
    final books = await _syncBooks(userId: userId);
    return SyncOrchestrationResult(books: books);
  }
}
