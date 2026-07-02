import 'package:uuid/uuid.dart';

import '../entities/remote_annual_goal.dart';
import '../entities/sync_metadata.dart';
import '../repositories/remote_annual_goals_repository.dart';
import '../repositories/sync_metadata_repository.dart';
import '../services/local_sync_tracker.dart';
import '../services/sync_debug_logger.dart';

typedef LocalAnnualGoalLoader = Future<int?> Function();
typedef RemoteAnnualGoalIdGenerator = String Function();
typedef AnnualGoalClock = DateTime Function();

class SyncPendingAnnualGoalResult {
  const SyncPendingAnnualGoalResult({
    required this.pendingAnnualGoals,
    required this.synced,
    required this.failed,
    required this.ignored,
    this.failureMessages = const [],
  });

  final int pendingAnnualGoals;
  final int synced;
  final int failed;
  final int ignored;
  final List<String> failureMessages;
}

class SyncPendingAnnualGoalToSupabase {
  SyncPendingAnnualGoalToSupabase({
    required SyncMetadataRepository metadataRepository,
    required RemoteAnnualGoalsRepository remoteAnnualGoalsRepository,
    required LocalAnnualGoalLoader loadAnnualGoal,
    RemoteAnnualGoalIdGenerator? remoteIdGenerator,
    AnnualGoalClock? clock,
  }) : _metadataRepository = metadataRepository,
       _remoteAnnualGoalsRepository = remoteAnnualGoalsRepository,
       _loadAnnualGoal = loadAnnualGoal,
       _remoteIdGenerator = remoteIdGenerator ?? const Uuid().v4,
       _clock = clock ?? DateTime.now;

  final SyncMetadataRepository _metadataRepository;
  final RemoteAnnualGoalsRepository _remoteAnnualGoalsRepository;
  final LocalAnnualGoalLoader _loadAnnualGoal;
  final RemoteAnnualGoalIdGenerator _remoteIdGenerator;
  final AnnualGoalClock _clock;

  Future<SyncPendingAnnualGoalResult> call({required String userId}) async {
    final pending = await _metadataRepository.getPendingSync();
    final pendingAnnualGoals = pending
        .where((metadata) => metadata.entityType == SyncEntityType.annualGoal)
        .toList();

    var synced = 0;
    var failed = 0;
    final failureMessages = <String>[];

    for (final metadata in pendingAnnualGoals) {
      try {
        switch (metadata.pendingOperation) {
          case PendingSyncOperation.create:
          case PendingSyncOperation.update:
            await _syncAnnualGoalUpsert(metadata: metadata, userId: userId);
            synced++;
            break;
          case PendingSyncOperation.delete:
            await _syncAnnualGoalDelete(metadata: metadata, userId: userId);
            synced++;
            break;
          case PendingSyncOperation.none:
            break;
        }
      } catch (error, stackTrace) {
        final message = syncFailureMessage(
          operation: metadata.pendingOperation.value,
          entityType: metadata.entityType.value,
          localId: metadata.localId,
          table: 'annual_goals',
          error: error,
        );
        failed++;
        failureMessages.add(message);
        logSyncDebugError(
          operation: metadata.pendingOperation.value,
          entityType: metadata.entityType.value,
          localId: metadata.localId,
          userId: userId,
          table: 'annual_goals',
          error: error,
          stackTrace: stackTrace,
        );
        await _metadataRepository.registerFailure(
          entityType: metadata.entityType,
          localId: metadata.localId,
          message: message,
        );
      }
    }

    return SyncPendingAnnualGoalResult(
      pendingAnnualGoals: pendingAnnualGoals.length,
      synced: synced,
      failed: failed,
      ignored: pending.length - pendingAnnualGoals.length,
      failureMessages: failureMessages,
    );
  }

  Future<void> _syncAnnualGoalUpsert({
    required SyncMetadata metadata,
    required String userId,
  }) async {
    final goal = await _loadAnnualGoal();
    if (goal == null) {
      throw StateError('Local annual goal not found: ${metadata.localId}');
    }

    final fallbackRemoteId = metadata.remoteId ?? _remoteIdGenerator();
    final remoteGoal = RemoteAnnualGoal(
      id: fallbackRemoteId,
      userId: userId,
      localGoalId: LocalSyncTracker.annualGoalLocalId,
      year: _clock().year,
      targetBooks: goal,
    );

    final syncedGoals = await _remoteAnnualGoalsRepository.upsertAnnualGoals([
      remoteGoal,
    ]);
    final syncedGoal = syncedGoals.isEmpty ? remoteGoal : syncedGoals.first;

    await _metadataRepository.markSynced(
      entityType: metadata.entityType,
      localId: metadata.localId,
      remoteId: syncedGoal.id,
      lastRemoteUpdate: syncedGoal.updatedAt,
    );
  }

  Future<void> _syncAnnualGoalDelete({
    required SyncMetadata metadata,
    required String userId,
  }) async {
    final remoteId = metadata.remoteId;

    if (remoteId != null) {
      await _remoteAnnualGoalsRepository.deleteAnnualGoal(
        userId: userId,
        goalId: remoteId,
      );
    }

    await _metadataRepository.markSynced(
      entityType: metadata.entityType,
      localId: metadata.localId,
      remoteId: remoteId,
    );
  }
}
