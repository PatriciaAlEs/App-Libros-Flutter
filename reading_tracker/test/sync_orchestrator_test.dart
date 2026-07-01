import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/sync/data/repositories/manual_books_sync_provider.dart';
import 'package:reading_tracker/features/sync/data/repositories/sync_orchestrator_provider.dart';
import 'package:reading_tracker/features/sync/domain/entities/remote_book.dart';
import 'package:reading_tracker/features/sync/domain/entities/sync_metadata.dart';
import 'package:reading_tracker/features/sync/domain/repositories/remote_books_repository.dart';
import 'package:reading_tracker/features/sync/domain/repositories/sync_metadata_repository.dart';
import 'package:reading_tracker/features/sync/domain/services/sync_orchestrator.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_books_to_supabase.dart';

void main() {
  test('runs books sync with the provided user id', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _metadata(localId: 'book-1'),
    ]);
    final remoteRepository = FakeRemoteBooksRepository();
    final syncBooks = SyncPendingBooksToSupabase(
      metadataRepository: metadataRepository,
      remoteBooksRepository: remoteRepository,
      loadBook: (localId) async => _book(id: localId),
      remoteIdGenerator: () => 'remote-book-1',
    );
    final orchestrator = SyncOrchestrator(syncBooks: syncBooks);

    final result = await orchestrator.runManualSync(userId: 'user-1');

    expect(remoteRepository.userIds, ['user-1']);
    expect(result.books.pendingBooks, 1);
    expect(result.synced, 1);
    expect(result.failed, 0);
    expect(result.ignored, 0);
  });

  test('returns aggregate counters from the books sync result', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _metadata(localId: 'book-1'),
      _metadata(
        entityType: SyncEntityType.readingSession,
        localId: 'session-1',
      ),
    ]);
    final remoteRepository = FakeRemoteBooksRepository();
    final syncBooks = SyncPendingBooksToSupabase(
      metadataRepository: metadataRepository,
      remoteBooksRepository: remoteRepository,
      loadBook: (localId) async => _book(id: localId),
      remoteIdGenerator: () => 'remote-book-1',
    );
    final orchestrator = SyncOrchestrator(syncBooks: syncBooks);

    final result = await orchestrator.runManualSync(userId: 'user-1');

    expect(result.books.synced, 1);
    expect(result.books.failed, 0);
    expect(result.books.ignored, 1);
    expect(result.synced, 1);
    expect(result.failed, 0);
    expect(result.ignored, 1);
  });

  test('propagates a full books sync failure', () async {
    final syncBooks = SyncPendingBooksToSupabase(
      metadataRepository: ThrowingSyncMetadataRepository(),
      remoteBooksRepository: FakeRemoteBooksRepository(),
      loadBook: (_) async => null,
    );
    final orchestrator = SyncOrchestrator(syncBooks: syncBooks);

    await expectLater(
      orchestrator.runManualSync(userId: 'user-1'),
      throwsA(isA<StateError>()),
    );
  });

  test('provider returns null when books sync is unavailable', () {
    final container = ProviderContainer(
      overrides: [
        syncPendingBooksToSupabaseProvider.overrideWith((ref) => null),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(syncOrchestratorProvider), isNull);
  });
}

Book _book({required String id}) {
  return Book(id: id, title: 'Book $id', createdAt: DateTime(2026, 7));
}

SyncMetadata _metadata({
  SyncEntityType entityType = SyncEntityType.book,
  required String localId,
}) {
  final now = DateTime(2026, 7);
  return SyncMetadata(
    id: 'sync-$localId',
    entityType: entityType,
    localId: localId,
    syncStatus: SyncStatus.pendingUpload,
    pendingOperation: PendingSyncOperation.create,
    createdAt: now,
    updatedAt: now,
  );
}

class FakeRemoteBooksRepository implements RemoteBooksRepository {
  final List<String> userIds = [];

  @override
  Future<void> deleteBook({
    required String userId,
    required String remoteBookId,
  }) async {
    userIds.add(userId);
  }

  @override
  Future<List<RemoteBook>> getBooks({
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  }) async {
    return const [];
  }

  @override
  Future<List<RemoteBook>> upsertBooks(List<RemoteBook> books) async {
    userIds.add(books.single.userId);
    return books;
  }
}

class FakeSyncMetadataRepository implements SyncMetadataRepository {
  FakeSyncMetadataRepository(this.pending);

  final List<SyncMetadata> pending;

  @override
  Future<void> associateRemoteId({
    required SyncEntityType entityType,
    required String localId,
    required String remoteId,
    DateTime? lastRemoteUpdate,
  }) async {}

  @override
  Future<SyncMetadata?> getByLocalId({
    required SyncEntityType entityType,
    required String localId,
  }) async {
    return null;
  }

  @override
  Future<List<SyncMetadata>> getPendingSync() async => pending;

  @override
  Future<void> markPendingDelete({
    required SyncEntityType entityType,
    required String localId,
    DateTime? localUpdate,
  }) async {}

  @override
  Future<void> markPendingUpdate({
    required SyncEntityType entityType,
    required String localId,
    DateTime? localUpdate,
  }) async {}

  @override
  Future<void> markPendingUpload({
    required SyncEntityType entityType,
    required String localId,
    DateTime? localUpdate,
  }) async {}

  @override
  Future<void> markSynced({
    required SyncEntityType entityType,
    required String localId,
    String? remoteId,
    DateTime? lastRemoteUpdate,
  }) async {}

  @override
  Future<void> registerFailure({
    required SyncEntityType entityType,
    required String localId,
    required String message,
  }) async {}

  @override
  Future<void> save(SyncMetadata metadata) async {}
}

class ThrowingSyncMetadataRepository extends FakeSyncMetadataRepository {
  ThrowingSyncMetadataRepository() : super(const []);

  @override
  Future<List<SyncMetadata>> getPendingSync() {
    throw StateError('Books sync failed before processing records');
  }
}
