enum SyncUiStatus { idle, syncing, synced, pendingChanges, conflict, failed }

enum LastSyncResultStatus { completed, failed, skippedAlreadyRunning }

class LastSyncResult {
  const LastSyncResult({
    required this.status,
    required this.finishedAt,
    this.message,
    this.uploadSynced = 0,
    this.downloadApplied = 0,
    this.downloadConflicts = 0,
  });

  final LastSyncResultStatus status;
  final DateTime finishedAt;
  final String? message;
  final int uploadSynced;
  final int downloadApplied;
  final int downloadConflicts;

  bool get isFailure => status == LastSyncResultStatus.failed;
}

class SyncStatusState {
  const SyncStatusState({
    required this.status,
    this.lastSyncAt,
    this.lastSyncResult,
    this.pendingCount = 0,
    this.conflictCount = 0,
    this.failedCount = 0,
  });

  const SyncStatusState.idle() : this(status: SyncUiStatus.idle);

  final SyncUiStatus status;
  final DateTime? lastSyncAt;
  final LastSyncResult? lastSyncResult;
  final int pendingCount;
  final int conflictCount;
  final int failedCount;

  SyncStatusState copyWith({
    SyncUiStatus? status,
    DateTime? lastSyncAt,
    LastSyncResult? lastSyncResult,
    int? pendingCount,
    int? conflictCount,
    int? failedCount,
    bool clearLastSyncAt = false,
    bool clearLastSyncResult = false,
  }) {
    return SyncStatusState(
      status: status ?? this.status,
      lastSyncAt: clearLastSyncAt ? null : lastSyncAt ?? this.lastSyncAt,
      lastSyncResult: clearLastSyncResult
          ? null
          : lastSyncResult ?? this.lastSyncResult,
      pendingCount: pendingCount ?? this.pendingCount,
      conflictCount: conflictCount ?? this.conflictCount,
      failedCount: failedCount ?? this.failedCount,
    );
  }
}

class SyncMetadataSummary {
  const SyncMetadataSummary({
    this.pendingCount = 0,
    this.conflictCount = 0,
    this.failedCount = 0,
    this.lastSyncedAt,
    this.hasAnyMetadata = false,
  });

  final int pendingCount;
  final int conflictCount;
  final int failedCount;
  final DateTime? lastSyncedAt;
  final bool hasAnyMetadata;
}
