import '../entities/sync_metadata.dart';
import '../repositories/remote_annual_goals_repository.dart';
import '../repositories/sync_metadata_repository.dart';
import '../services/local_sync_tracker.dart';
import '../services/sync_debug_logger.dart';

typedef LocalAnnualGoalWriter = Future<void> Function(int goal);
typedef AnnualGoalDownloadClock = DateTime Function();

class DownloadAnnualGoalResult {
  const DownloadAnnualGoalResult({
    required this.remoteAnnualGoals,
    required this.applied,
    required this.skipped,
    required this.conflicts,
    required this.failed,
    this.failureMessages = const [],
  });

  final int remoteAnnualGoals;
  final int applied;
  final int skipped;
  final int conflicts;
  final int failed;
  final List<String> failureMessages;
}

class DownloadAnnualGoalFromSupabase {
  DownloadAnnualGoalFromSupabase({
    required RemoteAnnualGoalsRepository remoteAnnualGoalsRepository,
    required SyncMetadataRepository metadataRepository,
    required LocalAnnualGoalWriter writeAnnualGoal,
    AnnualGoalDownloadClock? clock,
  }) : _remoteAnnualGoalsRepository = remoteAnnualGoalsRepository,
       _metadataRepository = metadataRepository,
       _writeAnnualGoal = writeAnnualGoal,
       _clock = clock ?? DateTime.now;

  final RemoteAnnualGoalsRepository _remoteAnnualGoalsRepository;
  final SyncMetadataRepository _metadataRepository;
  final LocalAnnualGoalWriter _writeAnnualGoal;
  final AnnualGoalDownloadClock _clock;

  Future<DownloadAnnualGoalResult> call({required String userId}) async {
    final remoteGoals = await _remoteAnnualGoalsRepository.getAnnualGoals(
      userId: userId,
      includeDeleted: false,
    );
    final currentYear = _clock().year;

    var applied = 0;
    var skipped = 0;
    var conflicts = 0;
    var failed = 0;
    final failureMessages = <String>[];

    for (final remoteGoal in remoteGoals) {
      if (remoteGoal.deletedAt != null || remoteGoal.year != currentYear) {
        skipped++;
        continue;
      }

      try {
        final localId =
            remoteGoal.localGoalId ?? LocalSyncTracker.annualGoalLocalId;
        final metadata = await _metadataRepository.getByLocalId(
          entityType: SyncEntityType.annualGoal,
          localId: localId,
        );
        if (metadata?.hasPendingOperation ?? false) {
          if (_hasNewerRemoteVersion(metadata!, remoteGoal.updatedAt)) {
            await _metadataRepository.markConflict(
              entityType: SyncEntityType.annualGoal,
              localId: localId,
              remoteId: remoteGoal.id,
              lastRemoteUpdate: remoteGoal.updatedAt!,
              message: _conflictMessage(
                entityType: SyncEntityType.annualGoal,
                localId: localId,
                remoteId: remoteGoal.id,
                remoteUpdatedAt: remoteGoal.updatedAt!,
              ),
            );
            conflicts++;
          } else {
            skipped++;
          }
          continue;
        }

        await _writeAnnualGoal(remoteGoal.targetBooks);
        await _metadataRepository.markSynced(
          entityType: SyncEntityType.annualGoal,
          localId: localId,
          remoteId: remoteGoal.id,
          lastRemoteUpdate: remoteGoal.updatedAt,
        );
        applied++;
      } catch (error, stackTrace) {
        failed++;
        final localId =
            remoteGoal.localGoalId ?? LocalSyncTracker.annualGoalLocalId;
        final message = syncFailureMessage(
          operation: 'download',
          entityType: SyncEntityType.annualGoal.value,
          localId: localId,
          table: 'annual_goals',
          error: error,
        );
        failureMessages.add(message);
        logSyncDebugError(
          operation: 'download',
          entityType: SyncEntityType.annualGoal.value,
          localId: localId,
          userId: userId,
          table: 'annual_goals',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return DownloadAnnualGoalResult(
      remoteAnnualGoals: remoteGoals.length,
      applied: applied,
      skipped: skipped,
      conflicts: conflicts,
      failed: failed,
      failureMessages: failureMessages,
    );
  }
}

bool _hasNewerRemoteVersion(SyncMetadata metadata, DateTime? remoteUpdatedAt) {
  if (remoteUpdatedAt == null) return false;
  final lastRemoteUpdate = metadata.lastRemoteUpdate;
  return lastRemoteUpdate == null || remoteUpdatedAt.isAfter(lastRemoteUpdate);
}

String _conflictMessage({
  required SyncEntityType entityType,
  required String localId,
  required String remoteId,
  required DateTime remoteUpdatedAt,
}) {
  return 'Remote ${entityType.value} changed while local pending exists: '
      'localId=$localId remoteId=$remoteId remoteUpdatedAt=${remoteUpdatedAt.toIso8601String()}';
}
