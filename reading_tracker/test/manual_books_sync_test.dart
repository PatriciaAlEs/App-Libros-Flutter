import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/sync/domain/entities/remote_book.dart';
import 'package:reading_tracker/features/sync/domain/entities/sync_metadata.dart';
import 'package:reading_tracker/features/sync/domain/repositories/remote_books_repository.dart';
import 'package:reading_tracker/features/sync/domain/repositories/sync_metadata_repository.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_books_to_supabase.dart';

void main() {
  const userId = 'user-1';

  test('only synchronizes pending book metadata', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _metadata(
        entityType: SyncEntityType.book,
        localId: 'book-1',
        operation: PendingSyncOperation.create,
      ),
      _metadata(
        entityType: SyncEntityType.readingSession,
        localId: 'session-1',
        operation: PendingSyncOperation.create,
      ),
      _metadata(
        entityType: SyncEntityType.profile,
        localId: 'reader_profile',
        operation: PendingSyncOperation.update,
      ),
      _metadata(
        entityType: SyncEntityType.annualGoal,
        localId: 'annualReadingGoal',
        operation: PendingSyncOperation.update,
      ),
    ]);
    final remoteRepository = FakeRemoteBooksRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
      books: {'book-1': _book(id: 'book-1')},
    );

    final result = await useCase(userId: userId);

    expect(result.pendingBooks, 1);
    expect(result.synced, 1);
    expect(result.ignored, 3);
    expect(remoteRepository.upserted, hasLength(1));
    expect(metadataRepository.syncedLocalIds, ['book-1']);
  });

  test('create uploads local book and marks metadata as synced', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _metadata(localId: 'book-1', operation: PendingSyncOperation.create),
    ]);
    final remoteRepository = FakeRemoteBooksRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
      books: {'book-1': _book(id: 'book-1', status: BookStatus.reading)},
      remoteIds: ['remote-book-1'],
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 1);
    expect(result.failed, 0);
    expect(remoteRepository.upserted.single.localBookId, 'book-1');
    expect(remoteRepository.upserted.single.id, 'remote-book-1');
    expect(remoteRepository.upserted.single.status, 'reading');
    expect(metadataRepository.syncedRemoteIds['book-1'], 'remote-book-1');
  });

  test('create falls back to createdAt when local updatedAt is null', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _metadata(localId: 'book-1', operation: PendingSyncOperation.create),
    ]);
    final remoteRepository = FakeRemoteBooksRepository();
    final createdAt = DateTime(2026, 6, 27);
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
      books: {
        'book-1': _book(
          id: 'book-1',
          createdAt: createdAt,
          hasUpdatedAt: false,
        ),
      },
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 1);
    expect(remoteRepository.upserted.single.createdAt, createdAt);
    expect(remoteRepository.upserted.single.updatedAt, createdAt);
  });

  test(
    'update uploads existing remote book and marks metadata as synced',
    () async {
      final metadataRepository = FakeSyncMetadataRepository([
        _metadata(
          localId: 'book-1',
          remoteId: 'remote-book-1',
          operation: PendingSyncOperation.update,
        ),
      ]);
      final remoteRepository = FakeRemoteBooksRepository();
      final useCase = _useCase(
        metadataRepository: metadataRepository,
        remoteRepository: remoteRepository,
        books: {'book-1': _book(id: 'book-1', title: 'Updated book')},
      );

      final result = await useCase(userId: userId);

      expect(result.synced, 1);
      expect(remoteRepository.upserted.single.id, 'remote-book-1');
      expect(remoteRepository.upserted.single.title, 'Updated book');
      expect(metadataRepository.syncedLocalIds, ['book-1']);
    },
  );

  test('delete with remote id deletes remote book and marks synced', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _metadata(
        localId: 'book-1',
        remoteId: 'remote-book-1',
        operation: PendingSyncOperation.delete,
      ),
    ]);
    final remoteRepository = FakeRemoteBooksRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 1);
    expect(remoteRepository.deletedRemoteIds, ['remote-book-1']);
    expect(metadataRepository.syncedLocalIds, ['book-1']);
  });

  test('delete without remote id marks synced without remote delete', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _metadata(localId: 'book-1', operation: PendingSyncOperation.delete),
    ]);
    final remoteRepository = FakeRemoteBooksRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 1);
    expect(remoteRepository.deletedRemoteIds, isEmpty);
    expect(metadataRepository.syncedLocalIds, ['book-1']);
  });

  test('remote failure registers error and does not mark synced', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _metadata(localId: 'book-1', operation: PendingSyncOperation.create),
    ]);
    final remoteRepository = FakeRemoteBooksRepository(
      upsertError: Exception('Supabase is unavailable'),
    );
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
      books: {'book-1': _book(id: 'book-1')},
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 0);
    expect(result.failed, 1);
    expect(metadataRepository.syncedLocalIds, isEmpty);
    expect(metadataRepository.failures['book-1'], contains('Supabase'));
  });
}

SyncPendingBooksToSupabase _useCase({
  required FakeSyncMetadataRepository metadataRepository,
  required FakeRemoteBooksRepository remoteRepository,
  Map<String, Book> books = const {},
  List<String> remoteIds = const ['remote-book-generated'],
}) {
  var nextRemoteId = 0;

  return SyncPendingBooksToSupabase(
    metadataRepository: metadataRepository,
    remoteBooksRepository: remoteRepository,
    loadBook: (localId) async => books[localId],
    remoteIdGenerator: () => remoteIds[nextRemoteId++],
  );
}

Book _book({
  required String id,
  String? title,
  BookStatus status = BookStatus.pending,
  DateTime? createdAt,
  bool hasUpdatedAt = true,
}) {
  return Book(
    id: id,
    title: title ?? 'Book $id',
    author: 'Author',
    isbn: '123',
    coverUrl: 'https://example.com/cover.jpg',
    totalPages: 320,
    currentPage: 12,
    status: status,
    rating: 4,
    startDate: DateTime(2026, 6, 1),
    createdAt: createdAt ?? DateTime(2026, 6, 27),
    updatedAt: hasUpdatedAt ? DateTime(2026, 6, 28) : null,
  );
}

SyncMetadata _metadata({
  SyncEntityType entityType = SyncEntityType.book,
  required String localId,
  String? remoteId,
  required PendingSyncOperation operation,
}) {
  final now = DateTime(2026, 6, 27);
  return SyncMetadata(
    id: 'sync-$localId',
    entityType: entityType,
    localId: localId,
    remoteId: remoteId,
    syncStatus: switch (operation) {
      PendingSyncOperation.create => SyncStatus.pendingUpload,
      PendingSyncOperation.update => SyncStatus.pendingUpdate,
      PendingSyncOperation.delete => SyncStatus.pendingDelete,
      PendingSyncOperation.none => SyncStatus.synced,
    },
    pendingOperation: operation,
    createdAt: now,
    updatedAt: now,
  );
}

class FakeRemoteBooksRepository implements RemoteBooksRepository {
  FakeRemoteBooksRepository({this.upsertError});

  final Object? upsertError;
  final List<RemoteBook> upserted = [];
  final List<String> deletedRemoteIds = [];

  @override
  Future<void> deleteBook({
    required String userId,
    required String remoteBookId,
  }) async {
    deletedRemoteIds.add(remoteBookId);
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
    final error = upsertError;
    if (error != null) throw error;

    upserted.addAll(books);
    return books;
  }
}

class FakeSyncMetadataRepository implements SyncMetadataRepository {
  FakeSyncMetadataRepository(this.pending);

  final List<SyncMetadata> pending;
  final List<String> syncedLocalIds = [];
  final Map<String, String?> syncedRemoteIds = {};
  final Map<String, String> failures = {};

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
    for (final metadata in pending) {
      if (metadata.entityType == entityType && metadata.localId == localId) {
        return metadata;
      }
    }
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
  Future<void> markConflict({
    required SyncEntityType entityType,
    required String localId,
    required String remoteId,
    required DateTime lastRemoteUpdate,
    required String message,
  }) async {}

  @override
  Future<void> markSynced({
    required SyncEntityType entityType,
    required String localId,
    String? remoteId,
    DateTime? lastRemoteUpdate,
  }) async {
    syncedLocalIds.add(localId);
    syncedRemoteIds[localId] = remoteId;
  }

  @override
  Future<void> registerFailure({
    required SyncEntityType entityType,
    required String localId,
    required String message,
  }) async {
    failures[localId] = message;
  }

  @override
  Future<void> save(SyncMetadata metadata) async {}
}
