enum SyncEntityType {
  profile('profile'),
  book('book'),
  readingSession('reading_session'),
  annualGoal('annual_goal');

  const SyncEntityType(this.value);

  final String value;

  static SyncEntityType fromValue(String value) {
    return SyncEntityType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError.value(value, 'value'),
    );
  }
}

enum SyncStatus {
  notSynced('not_synced'),
  synced('synced'),
  pendingUpload('pending_upload'),
  pendingUpdate('pending_update'),
  pendingDelete('pending_delete'),
  conflict('conflict'),
  failed('failed');

  const SyncStatus(this.value);

  final String value;

  static SyncStatus fromValue(String value) {
    return SyncStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError.value(value, 'value'),
    );
  }
}

enum PendingSyncOperation {
  none('none'),
  create('create'),
  update('update'),
  delete('delete');

  const PendingSyncOperation(this.value);

  final String value;

  static PendingSyncOperation fromValue(String value) {
    return PendingSyncOperation.values.firstWhere(
      (operation) => operation.value == value,
      orElse: () => throw ArgumentError.value(value, 'value'),
    );
  }
}

class SyncMetadata {
  const SyncMetadata({
    required this.id,
    required this.entityType,
    required this.localId,
    required this.syncStatus,
    required this.pendingOperation,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.lastSyncedAt,
    this.lastLocalUpdate,
    this.lastRemoteUpdate,
    this.errorMessage,
    this.retryCount = 0,
  });

  final String id;
  final SyncEntityType entityType;
  final String localId;
  final String? remoteId;
  final SyncStatus syncStatus;
  final PendingSyncOperation pendingOperation;
  final DateTime? lastSyncedAt;
  final DateTime? lastLocalUpdate;
  final DateTime? lastRemoteUpdate;
  final String? errorMessage;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasPendingOperation => pendingOperation != PendingSyncOperation.none;
}
