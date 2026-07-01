import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/sync/domain/entities/remote_reading_session.dart';
import 'package:reading_tracker/features/sync/domain/entities/sync_metadata.dart';
import 'package:reading_tracker/features/sync/domain/repositories/remote_reading_sessions_repository.dart';
import 'package:reading_tracker/features/sync/domain/repositories/sync_metadata_repository.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_reading_sessions_to_supabase.dart';

void main() {
  const userId = 'user-1';

  test('create uploads reading session and marks metadata as synced', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _bookMetadata(localId: 'book-1', remoteId: 'remote-book-1'),
      _sessionMetadata(
        localId: 'session-1',
        operation: PendingSyncOperation.create,
      ),
    ]);
    final remoteRepository = FakeRemoteReadingSessionsRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
      sessions: {'session-1': _session(id: 'session-1')},
      remoteIds: ['remote-session-1'],
    );

    final result = await useCase(userId: userId);

    expect(result.pendingReadingSessions, 1);
    expect(result.synced, 1);
    expect(result.failed, 0);
    expect(remoteRepository.upserted.single.id, 'remote-session-1');
    expect(remoteRepository.upserted.single.remoteBookId, 'remote-book-1');
    expect(remoteRepository.upserted.single.localBookId, 'book-1');
    expect(metadataRepository.syncedRemoteIds['session-1'], 'remote-session-1');
  });

  test('update uploads existing remote session and marks synced', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _bookMetadata(localId: 'book-1', remoteId: 'remote-book-1'),
      _sessionMetadata(
        localId: 'session-1',
        remoteId: 'remote-session-1',
        operation: PendingSyncOperation.update,
      ),
    ]);
    final remoteRepository = FakeRemoteReadingSessionsRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
      sessions: {
        'session-1': _session(id: 'session-1', minutes: 45, pagesRead: 20),
      },
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 1);
    expect(remoteRepository.upserted.single.id, 'remote-session-1');
    expect(remoteRepository.upserted.single.minutesRead, 45);
    expect(remoteRepository.upserted.single.pagesRead, 20);
    expect(metadataRepository.syncedLocalIds, ['session-1']);
  });

  test(
    'delete with remote id deletes remote session and marks synced',
    () async {
      final metadataRepository = FakeSyncMetadataRepository([
        _sessionMetadata(
          localId: 'session-1',
          remoteId: 'remote-session-1',
          operation: PendingSyncOperation.delete,
        ),
      ]);
      final remoteRepository = FakeRemoteReadingSessionsRepository();
      final useCase = _useCase(
        metadataRepository: metadataRepository,
        remoteRepository: remoteRepository,
      );

      final result = await useCase(userId: userId);

      expect(result.synced, 1);
      expect(remoteRepository.deletedRemoteIds, ['remote-session-1']);
      expect(metadataRepository.syncedLocalIds, ['session-1']);
    },
  );

  test('delete without remote id marks synced without remote delete', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _sessionMetadata(
        localId: 'session-1',
        operation: PendingSyncOperation.delete,
      ),
    ]);
    final remoteRepository = FakeRemoteReadingSessionsRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 1);
    expect(remoteRepository.deletedRemoteIds, isEmpty);
    expect(metadataRepository.syncedLocalIds, ['session-1']);
  });

  test('remote failure registers error and does not mark synced', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _bookMetadata(localId: 'book-1', remoteId: 'remote-book-1'),
      _sessionMetadata(
        localId: 'session-1',
        operation: PendingSyncOperation.create,
      ),
    ]);
    final remoteRepository = FakeRemoteReadingSessionsRepository(
      upsertError: Exception('Supabase is unavailable'),
    );
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
      sessions: {'session-1': _session(id: 'session-1')},
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 0);
    expect(result.failed, 1);
    expect(metadataRepository.syncedLocalIds, isEmpty);
    expect(metadataRepository.failures['session-1'], contains('Supabase'));
  });

  test('session whose book has no remote id registers failure', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _bookMetadata(localId: 'book-1'),
      _sessionMetadata(
        localId: 'session-1',
        operation: PendingSyncOperation.create,
      ),
    ]);
    final remoteRepository = FakeRemoteReadingSessionsRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
      sessions: {'session-1': _session(id: 'session-1')},
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 0);
    expect(result.failed, 1);
    expect(remoteRepository.upserted, isEmpty);
    expect(
      metadataRepository.failures['session-1'],
      contains('Remote book id'),
    );
  });

  test('ignores metadata that is not a reading session', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _bookMetadata(localId: 'book-1', remoteId: 'remote-book-1'),
      _sessionMetadata(
        localId: 'session-1',
        operation: PendingSyncOperation.create,
      ),
    ]);
    final remoteRepository = FakeRemoteReadingSessionsRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
      sessions: {'session-1': _session(id: 'session-1')},
    );

    final result = await useCase(userId: userId);

    expect(result.pendingReadingSessions, 1);
    expect(result.ignored, 1);
    expect(result.synced, 1);
  });
}

SyncPendingReadingSessionsToSupabase _useCase({
  required FakeSyncMetadataRepository metadataRepository,
  required FakeRemoteReadingSessionsRepository remoteRepository,
  Map<String, ReadingSession> sessions = const {},
  List<String> remoteIds = const ['remote-session-generated'],
}) {
  var nextRemoteId = 0;

  return SyncPendingReadingSessionsToSupabase(
    metadataRepository: metadataRepository,
    remoteReadingSessionsRepository: remoteRepository,
    loadSession: (localId) async => sessions[localId],
    remoteIdGenerator: () => remoteIds[nextRemoteId++],
  );
}

ReadingSession _session({
  required String id,
  String bookId = 'book-1',
  int minutes = 30,
  int pagesRead = 12,
}) {
  return ReadingSession(
    id: id,
    bookId: bookId,
    date: DateTime(2026, 7, 1),
    minutes: minutes,
    pagesRead: pagesRead,
    note: 'Nice chapter',
    createdAt: DateTime(2026, 7, 1, 10),
    updatedAt: DateTime(2026, 7, 1, 11),
  );
}

SyncMetadata _bookMetadata({required String localId, String? remoteId}) {
  return _metadata(
    entityType: SyncEntityType.book,
    localId: localId,
    remoteId: remoteId,
    operation: PendingSyncOperation.create,
  );
}

SyncMetadata _sessionMetadata({
  required String localId,
  String? remoteId,
  required PendingSyncOperation operation,
}) {
  return _metadata(
    entityType: SyncEntityType.readingSession,
    localId: localId,
    remoteId: remoteId,
    operation: operation,
  );
}

SyncMetadata _metadata({
  required SyncEntityType entityType,
  required String localId,
  String? remoteId,
  required PendingSyncOperation operation,
}) {
  final now = DateTime(2026, 7, 1);
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

class FakeRemoteReadingSessionsRepository
    implements RemoteReadingSessionsRepository {
  FakeRemoteReadingSessionsRepository({this.upsertError});

  final Object? upsertError;
  final List<RemoteReadingSession> upserted = [];
  final List<String> deletedRemoteIds = [];

  @override
  Future<void> deleteReadingSession({
    required String userId,
    required String remoteSessionId,
  }) async {
    deletedRemoteIds.add(remoteSessionId);
  }

  @override
  Future<List<RemoteReadingSession>> getReadingSessions({
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  }) async {
    return const [];
  }

  @override
  Future<List<RemoteReadingSession>> upsertReadingSessions(
    List<RemoteReadingSession> sessions,
  ) async {
    final error = upsertError;
    if (error != null) throw error;

    upserted.addAll(sessions);
    return sessions;
  }
}

class FakeSyncMetadataRepository implements SyncMetadataRepository {
  FakeSyncMetadataRepository(this.metadata);

  final List<SyncMetadata> metadata;
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
    for (final item in metadata) {
      if (item.entityType == entityType && item.localId == localId) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<List<SyncMetadata>> getPendingSync() async {
    return metadata.where((item) => item.hasPendingOperation).toList();
  }

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
