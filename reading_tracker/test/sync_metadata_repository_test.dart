import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/core/database/app_database.dart';
import 'package:reading_tracker/features/sync/data/repositories/local_sync_metadata_repository.dart';
import 'package:reading_tracker/features/sync/domain/entities/sync_metadata.dart';

void main() {
  late AppDatabase database;
  late LocalSyncMetadataRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LocalSyncMetadataRepository(database.syncMetadataDao);
  });

  tearDown(() => database.close());

  group('Sync metadata enums', () {
    test('serialize and deserialize domain values', () {
      expect(SyncEntityType.fromValue('book'), SyncEntityType.book);
      expect(
        SyncEntityType.fromValue('reading_session'),
        SyncEntityType.readingSession,
      );
      expect(SyncStatus.fromValue('pending_update'), SyncStatus.pendingUpdate);
      expect(
        PendingSyncOperation.fromValue('delete'),
        PendingSyncOperation.delete,
      );
    });
  });

  group('LocalSyncMetadataRepository', () {
    test('creates and reads metadata by entity and local id', () async {
      final metadata = _metadata(
        id: 'sync-1',
        entityType: SyncEntityType.book,
        localId: 'book-1',
      );

      await repository.save(metadata);

      final saved = await repository.getByLocalId(
        entityType: SyncEntityType.book,
        localId: 'book-1',
      );

      expect(saved, isNotNull);
      expect(saved!.id, 'sync-1');
      expect(saved.entityType, SyncEntityType.book);
      expect(saved.localId, 'book-1');
      expect(saved.syncStatus, SyncStatus.notSynced);
      expect(saved.pendingOperation, PendingSyncOperation.none);
    });

    test('returns only metadata with pending operations', () async {
      await repository.save(
        _metadata(
          id: 'sync-1',
          entityType: SyncEntityType.book,
          localId: 'book-1',
        ),
      );
      await repository.save(
        _metadata(
          id: 'sync-2',
          entityType: SyncEntityType.readingSession,
          localId: 'session-1',
        ),
      );

      await repository.markPendingUpload(
        entityType: SyncEntityType.book,
        localId: 'book-1',
        localUpdate: DateTime(2026, 6, 27, 9),
      );

      final pending = await repository.getPendingSync();

      expect(pending, hasLength(1));
      expect(pending.single.localId, 'book-1');
      expect(pending.single.syncStatus, SyncStatus.pendingUpload);
      expect(pending.single.pendingOperation, PendingSyncOperation.create);
      expect(pending.single.hasPendingOperation, isTrue);
    });

    test('associates remote id without changing pending status', () async {
      await repository.save(
        _metadata(
          id: 'sync-1',
          entityType: SyncEntityType.book,
          localId: 'book-1',
        ),
      );

      await repository.associateRemoteId(
        entityType: SyncEntityType.book,
        localId: 'book-1',
        remoteId: 'remote-book-1',
        lastRemoteUpdate: DateTime(2026, 6, 27, 10),
      );

      final saved = await repository.getByLocalId(
        entityType: SyncEntityType.book,
        localId: 'book-1',
      );

      expect(saved!.remoteId, 'remote-book-1');
      expect(saved.syncStatus, SyncStatus.notSynced);
      expect(saved.pendingOperation, PendingSyncOperation.none);
      expect(saved.lastRemoteUpdate, DateTime(2026, 6, 27, 10));
    });

    test('marks metadata as synced and clears failure state', () async {
      await repository.save(
        _metadata(
          id: 'sync-1',
          entityType: SyncEntityType.book,
          localId: 'book-1',
          syncStatus: SyncStatus.failed,
          pendingOperation: PendingSyncOperation.create,
          errorMessage: 'Network error',
          retryCount: 2,
        ),
      );

      await repository.markSynced(
        entityType: SyncEntityType.book,
        localId: 'book-1',
        remoteId: 'remote-book-1',
        lastRemoteUpdate: DateTime(2026, 6, 27, 11),
      );

      final saved = await repository.getByLocalId(
        entityType: SyncEntityType.book,
        localId: 'book-1',
      );

      expect(saved!.remoteId, 'remote-book-1');
      expect(saved.syncStatus, SyncStatus.synced);
      expect(saved.pendingOperation, PendingSyncOperation.none);
      expect(saved.lastSyncedAt, isNotNull);
      expect(saved.lastRemoteUpdate, DateTime(2026, 6, 27, 11));
      expect(saved.errorMessage, isNull);
      expect(saved.retryCount, 0);
    });

    test('marks metadata as pending update and pending delete', () async {
      await repository.save(
        _metadata(
          id: 'sync-1',
          entityType: SyncEntityType.book,
          localId: 'book-1',
        ),
      );

      await repository.markPendingUpdate(
        entityType: SyncEntityType.book,
        localId: 'book-1',
        localUpdate: DateTime(2026, 6, 27, 12),
      );

      var saved = await repository.getByLocalId(
        entityType: SyncEntityType.book,
        localId: 'book-1',
      );
      expect(saved!.syncStatus, SyncStatus.pendingUpdate);
      expect(saved.pendingOperation, PendingSyncOperation.update);
      expect(saved.lastLocalUpdate, DateTime(2026, 6, 27, 12));

      await repository.markPendingDelete(
        entityType: SyncEntityType.book,
        localId: 'book-1',
        localUpdate: DateTime(2026, 6, 27, 13),
      );

      saved = await repository.getByLocalId(
        entityType: SyncEntityType.book,
        localId: 'book-1',
      );
      expect(saved!.syncStatus, SyncStatus.pendingDelete);
      expect(saved.pendingOperation, PendingSyncOperation.delete);
      expect(saved.lastLocalUpdate, DateTime(2026, 6, 27, 13));
    });

    test('registers failures and increments retry count', () async {
      await repository.save(
        _metadata(
          id: 'sync-1',
          entityType: SyncEntityType.book,
          localId: 'book-1',
        ),
      );

      await repository.registerFailure(
        entityType: SyncEntityType.book,
        localId: 'book-1',
        message: 'First failure',
      );
      await repository.registerFailure(
        entityType: SyncEntityType.book,
        localId: 'book-1',
        message: 'Second failure',
      );

      final saved = await repository.getByLocalId(
        entityType: SyncEntityType.book,
        localId: 'book-1',
      );

      expect(saved!.syncStatus, SyncStatus.failed);
      expect(saved.errorMessage, 'Second failure');
      expect(saved.retryCount, 2);
    });
  });
}

SyncMetadata _metadata({
  required String id,
  required SyncEntityType entityType,
  required String localId,
  SyncStatus syncStatus = SyncStatus.notSynced,
  PendingSyncOperation pendingOperation = PendingSyncOperation.none,
  String? remoteId,
  String? errorMessage,
  int retryCount = 0,
}) {
  final now = DateTime(2026, 6, 27);
  return SyncMetadata(
    id: id,
    entityType: entityType,
    localId: localId,
    remoteId: remoteId,
    syncStatus: syncStatus,
    pendingOperation: pendingOperation,
    errorMessage: errorMessage,
    retryCount: retryCount,
    createdAt: now,
    updatedAt: now,
  );
}
