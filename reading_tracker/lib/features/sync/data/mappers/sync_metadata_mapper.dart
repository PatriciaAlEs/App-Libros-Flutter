import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/sync_metadata.dart';

extension SyncMetadataRowMapper on SyncMetadataTableData {
  SyncMetadata toDomain() {
    return SyncMetadata(
      id: id,
      entityType: SyncEntityType.fromValue(entityType),
      localId: localId,
      remoteId: remoteId,
      syncStatus: SyncStatus.fromValue(syncStatus),
      pendingOperation: PendingSyncOperation.fromValue(pendingOperation),
      lastSyncedAt: lastSyncedAt,
      lastLocalUpdate: lastLocalUpdate,
      lastRemoteUpdate: lastRemoteUpdate,
      errorMessage: errorMessage,
      retryCount: retryCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension SyncMetadataMapper on SyncMetadata {
  SyncMetadataTableCompanion toCompanion() {
    return SyncMetadataTableCompanion.insert(
      id: id,
      entityType: entityType.value,
      localId: localId,
      syncStatus: syncStatus.value,
      pendingOperation: pendingOperation.value,
      remoteId: Value(remoteId),
      lastSyncedAt: Value(lastSyncedAt),
      lastLocalUpdate: Value(lastLocalUpdate),
      lastRemoteUpdate: Value(lastRemoteUpdate),
      errorMessage: Value(errorMessage),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}
