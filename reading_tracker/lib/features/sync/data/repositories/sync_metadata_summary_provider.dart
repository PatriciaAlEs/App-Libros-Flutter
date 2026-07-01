import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../domain/entities/sync_metadata.dart';
import '../../domain/entities/sync_status_state.dart';

final syncMetadataSummaryProvider = StreamProvider<SyncMetadataSummary>((ref) {
  final dao = ref.watch(databaseProvider).syncMetadataDao;
  return dao.watchAllMetadata().map((rows) {
    DateTime? lastSyncedAt;
    var pendingCount = 0;
    var conflictCount = 0;
    var failedCount = 0;

    for (final row in rows) {
      if (row.pendingOperation != PendingSyncOperation.none.value) {
        pendingCount++;
      }
      if (row.syncStatus == SyncStatus.conflict.value) {
        conflictCount++;
      }
      if (row.syncStatus == SyncStatus.failed.value) {
        failedCount++;
      }
      final syncedAt = row.lastSyncedAt;
      if (syncedAt != null &&
          (lastSyncedAt == null || syncedAt.isAfter(lastSyncedAt))) {
        lastSyncedAt = syncedAt;
      }
    }

    return SyncMetadataSummary(
      pendingCount: pendingCount,
      conflictCount: conflictCount,
      failedCount: failedCount,
      lastSyncedAt: lastSyncedAt,
      hasAnyMetadata: rows.isNotEmpty,
    );
  });
});
