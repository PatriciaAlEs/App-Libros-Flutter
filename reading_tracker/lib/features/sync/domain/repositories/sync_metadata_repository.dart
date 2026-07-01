import '../entities/sync_metadata.dart';

abstract interface class SyncMetadataRepository {
  Future<void> save(SyncMetadata metadata);

  Future<SyncMetadata?> getByLocalId({
    required SyncEntityType entityType,
    required String localId,
  });

  Future<List<SyncMetadata>> getPendingSync();

  Future<void> associateRemoteId({
    required SyncEntityType entityType,
    required String localId,
    required String remoteId,
    DateTime? lastRemoteUpdate,
  });

  Future<void> markSynced({
    required SyncEntityType entityType,
    required String localId,
    String? remoteId,
    DateTime? lastRemoteUpdate,
  });

  Future<void> markPendingUpload({
    required SyncEntityType entityType,
    required String localId,
    DateTime? localUpdate,
  });

  Future<void> markPendingUpdate({
    required SyncEntityType entityType,
    required String localId,
    DateTime? localUpdate,
  });

  Future<void> markPendingDelete({
    required SyncEntityType entityType,
    required String localId,
    DateTime? localUpdate,
  });

  Future<void> markConflict({
    required SyncEntityType entityType,
    required String localId,
    required String remoteId,
    required DateTime lastRemoteUpdate,
    required String message,
  });

  Future<void> registerFailure({
    required SyncEntityType entityType,
    required String localId,
    required String message,
  });
}
