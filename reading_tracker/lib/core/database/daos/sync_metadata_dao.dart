import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sync_metadata_table.dart';

part 'sync_metadata_dao.g.dart';

@DriftAccessor(tables: [SyncMetadataTable])
class SyncMetadataDao extends DatabaseAccessor<AppDatabase>
    with _$SyncMetadataDaoMixin {
  SyncMetadataDao(super.db);

  Future<void> upsertMetadata(SyncMetadataTableCompanion metadata) {
    return into(
      syncMetadataTable,
    ).insert(metadata, mode: InsertMode.insertOrReplace);
  }

  Future<SyncMetadataTableData?> getByEntity({
    required String entityType,
    required String localId,
  }) {
    return (select(syncMetadataTable)..where(
          (table) =>
              table.entityType.equals(entityType) &
              table.localId.equals(localId),
        ))
        .getSingleOrNull();
  }

  Future<List<SyncMetadataTableData>> getPendingSync() {
    return (select(syncMetadataTable)
          ..where((table) => table.pendingOperation.equals('none').not())
          ..orderBy([(table) => OrderingTerm.asc(table.updatedAt)]))
        .get();
  }

  Future<int> updateRemoteAssociation({
    required String entityType,
    required String localId,
    required String remoteId,
    required DateTime updatedAt,
    DateTime? lastRemoteUpdate,
  }) {
    return (update(syncMetadataTable)..where(
          (table) =>
              table.entityType.equals(entityType) &
              table.localId.equals(localId),
        ))
        .write(
          SyncMetadataTableCompanion(
            remoteId: Value(remoteId),
            lastRemoteUpdate: Value(lastRemoteUpdate),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<int> markSynced({
    required String entityType,
    required String localId,
    required String syncStatus,
    required String pendingOperation,
    required DateTime syncedAt,
    required DateTime updatedAt,
    String? remoteId,
    DateTime? lastRemoteUpdate,
  }) {
    return (update(syncMetadataTable)..where(
          (table) =>
              table.entityType.equals(entityType) &
              table.localId.equals(localId),
        ))
        .write(
          SyncMetadataTableCompanion(
            remoteId: Value.absentIfNull(remoteId),
            syncStatus: Value(syncStatus),
            pendingOperation: Value(pendingOperation),
            lastSyncedAt: Value(syncedAt),
            lastRemoteUpdate: Value(lastRemoteUpdate),
            errorMessage: const Value(null),
            retryCount: const Value(0),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<int> markPending({
    required String entityType,
    required String localId,
    required String syncStatus,
    required String pendingOperation,
    required DateTime localUpdate,
    required DateTime updatedAt,
  }) {
    return (update(syncMetadataTable)..where(
          (table) =>
              table.entityType.equals(entityType) &
              table.localId.equals(localId),
        ))
        .write(
          SyncMetadataTableCompanion(
            syncStatus: Value(syncStatus),
            pendingOperation: Value(pendingOperation),
            lastLocalUpdate: Value(localUpdate),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<int> markConflict({
    required String entityType,
    required String localId,
    required String syncStatus,
    required String remoteId,
    required DateTime lastRemoteUpdate,
    required String errorMessage,
    required DateTime updatedAt,
  }) {
    return (update(syncMetadataTable)..where(
          (table) =>
              table.entityType.equals(entityType) &
              table.localId.equals(localId),
        ))
        .write(
          SyncMetadataTableCompanion(
            remoteId: Value(remoteId),
            syncStatus: Value(syncStatus),
            lastRemoteUpdate: Value(lastRemoteUpdate),
            errorMessage: Value(errorMessage),
            updatedAt: Value(updatedAt),
          ),
        );
  }

  Future<int> registerFailure({
    required String entityType,
    required String localId,
    required String syncStatus,
    required String errorMessage,
    required int retryCount,
    required DateTime updatedAt,
  }) {
    return (update(syncMetadataTable)..where(
          (table) =>
              table.entityType.equals(entityType) &
              table.localId.equals(localId),
        ))
        .write(
          SyncMetadataTableCompanion(
            syncStatus: Value(syncStatus),
            errorMessage: Value(errorMessage),
            retryCount: Value(retryCount),
            updatedAt: Value(updatedAt),
          ),
        );
  }
}
