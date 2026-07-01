import 'package:uuid/uuid.dart';

import '../../../../core/database/daos/sync_metadata_dao.dart';
import '../../domain/entities/sync_metadata.dart';
import '../../domain/repositories/sync_metadata_repository.dart';
import '../mappers/sync_metadata_mapper.dart';

class LocalSyncMetadataRepository implements SyncMetadataRepository {
  LocalSyncMetadataRepository(this._dao, {String Function()? idGenerator})
    : _idGenerator = idGenerator ?? const Uuid().v4;

  final SyncMetadataDao _dao;
  final String Function() _idGenerator;

  @override
  Future<void> save(SyncMetadata metadata) {
    return _dao.upsertMetadata(metadata.toCompanion());
  }

  @override
  Future<SyncMetadata?> getByLocalId({
    required SyncEntityType entityType,
    required String localId,
  }) async {
    final row = await _dao.getByEntity(
      entityType: entityType.value,
      localId: localId,
    );
    return row?.toDomain();
  }

  @override
  Future<List<SyncMetadata>> getPendingSync() async {
    final rows = await _dao.getPendingSync();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<void> associateRemoteId({
    required SyncEntityType entityType,
    required String localId,
    required String remoteId,
    DateTime? lastRemoteUpdate,
  }) async {
    await _dao.updateRemoteAssociation(
      entityType: entityType.value,
      localId: localId,
      remoteId: remoteId,
      lastRemoteUpdate: lastRemoteUpdate,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> markSynced({
    required SyncEntityType entityType,
    required String localId,
    String? remoteId,
    DateTime? lastRemoteUpdate,
  }) async {
    final now = DateTime.now();
    final updatedRows = await _dao.markSynced(
      entityType: entityType.value,
      localId: localId,
      remoteId: remoteId,
      lastRemoteUpdate: lastRemoteUpdate,
      syncStatus: SyncStatus.synced.value,
      pendingOperation: PendingSyncOperation.none.value,
      syncedAt: now,
      updatedAt: now,
    );
    if (updatedRows > 0) return;

    await save(
      SyncMetadata(
        id: _idGenerator(),
        entityType: entityType,
        localId: localId,
        remoteId: remoteId,
        syncStatus: SyncStatus.synced,
        pendingOperation: PendingSyncOperation.none,
        lastSyncedAt: now,
        lastRemoteUpdate: lastRemoteUpdate,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> markPendingUpload({
    required SyncEntityType entityType,
    required String localId,
    DateTime? localUpdate,
  }) {
    return _markPending(
      entityType: entityType,
      localId: localId,
      syncStatus: SyncStatus.pendingUpload,
      operation: PendingSyncOperation.create,
      localUpdate: localUpdate,
    );
  }

  @override
  Future<void> markPendingUpdate({
    required SyncEntityType entityType,
    required String localId,
    DateTime? localUpdate,
  }) {
    return _markPending(
      entityType: entityType,
      localId: localId,
      syncStatus: SyncStatus.pendingUpdate,
      operation: PendingSyncOperation.update,
      localUpdate: localUpdate,
    );
  }

  @override
  Future<void> markPendingDelete({
    required SyncEntityType entityType,
    required String localId,
    DateTime? localUpdate,
  }) {
    return _markPending(
      entityType: entityType,
      localId: localId,
      syncStatus: SyncStatus.pendingDelete,
      operation: PendingSyncOperation.delete,
      localUpdate: localUpdate,
    );
  }

  Future<void> _markPending({
    required SyncEntityType entityType,
    required String localId,
    required SyncStatus syncStatus,
    required PendingSyncOperation operation,
    DateTime? localUpdate,
  }) async {
    final now = DateTime.now();
    await _dao.markPending(
      entityType: entityType.value,
      localId: localId,
      syncStatus: syncStatus.value,
      pendingOperation: operation.value,
      localUpdate: localUpdate ?? now,
      updatedAt: now,
    );
  }

  @override
  Future<void> markConflict({
    required SyncEntityType entityType,
    required String localId,
    required String remoteId,
    required DateTime lastRemoteUpdate,
    required String message,
  }) async {
    await _dao.markConflict(
      entityType: entityType.value,
      localId: localId,
      syncStatus: SyncStatus.conflict.value,
      remoteId: remoteId,
      lastRemoteUpdate: lastRemoteUpdate,
      errorMessage: message,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> registerFailure({
    required SyncEntityType entityType,
    required String localId,
    required String message,
  }) async {
    final existing = await getByLocalId(
      entityType: entityType,
      localId: localId,
    );
    await _dao.registerFailure(
      entityType: entityType.value,
      localId: localId,
      syncStatus: SyncStatus.failed.value,
      errorMessage: message,
      retryCount: (existing?.retryCount ?? 0) + 1,
      updatedAt: DateTime.now(),
    );
  }
}
