import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:reading_tracker/core/database/app_database.dart';
import 'package:reading_tracker/core/database/database_provider.dart';
import 'package:reading_tracker/features/sync/data/repositories/local_sync_metadata_repository.dart';
import 'package:reading_tracker/features/sync/data/repositories/sync_metadata_summary_provider.dart';
import 'package:reading_tracker/features/sync/domain/entities/sync_metadata.dart';
import 'package:reading_tracker/features/sync/domain/entities/sync_status_state.dart';
import 'package:reading_tracker/features/sync/domain/services/auto_sync_coordinator.dart';
import 'package:reading_tracker/features/sync/domain/services/sync_orchestrator.dart';
import 'package:reading_tracker/features/sync/domain/usecases/download_annual_goal_from_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/download_books_from_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/download_reader_profile_from_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/download_reading_sessions_from_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_annual_goal_to_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_books_to_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_reader_profile_to_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_reading_sessions_to_supabase.dart';
import 'package:reading_tracker/features/sync/presentation/controllers/sync_status_controller.dart';

void main() {
  test('resolves idle when there is no metadata or runtime result', () {
    final state = SyncStatusController.mergeState(
      runtime: const SyncStatusState.idle(),
      summary: const SyncMetadataSummary(),
    );

    expect(state.status, SyncUiStatus.idle);
    expect(state.pendingCount, 0);
    expect(state.conflictCount, 0);
  });

  test('resolves syncing with highest priority', () {
    final state = SyncStatusController.mergeState(
      runtime: const SyncStatusState(status: SyncUiStatus.syncing),
      summary: const SyncMetadataSummary(
        pendingCount: 1,
        conflictCount: 1,
        failedCount: 1,
      ),
    );

    expect(state.status, SyncUiStatus.syncing);
  });

  test('resolves conflict before failed and pending changes', () {
    final state = SyncStatusController.mergeState(
      runtime: SyncStatusState(
        status: SyncUiStatus.failed,
        lastSyncResult: LastSyncResult(
          status: LastSyncResultStatus.failed,
          finishedAt: DateTime(2026, 7),
        ),
      ),
      summary: const SyncMetadataSummary(
        pendingCount: 2,
        conflictCount: 1,
        failedCount: 1,
      ),
    );

    expect(state.status, SyncUiStatus.conflict);
    expect(state.pendingCount, 2);
    expect(state.conflictCount, 1);
  });

  test('resolves failed from runtime result or persisted failures', () {
    final runtimeFailed = SyncStatusController.mergeState(
      runtime: SyncStatusState(
        status: SyncUiStatus.failed,
        lastSyncResult: LastSyncResult(
          status: LastSyncResultStatus.failed,
          finishedAt: DateTime(2026, 7),
        ),
      ),
      summary: const SyncMetadataSummary(),
    );
    final metadataFailed = SyncStatusController.mergeState(
      runtime: const SyncStatusState.idle(),
      summary: const SyncMetadataSummary(failedCount: 1),
    );

    expect(runtimeFailed.status, SyncUiStatus.failed);
    expect(metadataFailed.status, SyncUiStatus.failed);
  });

  test('resolves pendingChanges before synced', () {
    final state = SyncStatusController.mergeState(
      runtime: const SyncStatusState.idle(),
      summary: SyncMetadataSummary(
        pendingCount: 1,
        lastSyncedAt: DateTime(2026, 7),
        hasAnyMetadata: true,
      ),
    );

    expect(state.status, SyncUiStatus.pendingChanges);
  });

  test('resolves synced when there is a last sync timestamp', () {
    final state = SyncStatusController.mergeState(
      runtime: const SyncStatusState.idle(),
      summary: SyncMetadataSummary(
        lastSyncedAt: DateTime(2026, 7),
        hasAnyMetadata: true,
      ),
    );

    expect(state.status, SyncUiStatus.synced);
    expect(state.lastSyncAt, DateTime(2026, 7));
  });

  test('syncNow exposes lightweight last sync result', () async {
    final controller = SyncStatusController(
      coordinator: AutoSyncCoordinator.withRunners(
        runUpload: ({required userId}) async => _uploadResult(),
        runDownload: ({required userId}) async => _downloadResult(),
      ),
      clock: () => DateTime(2026, 7, 1, 10),
    );

    await controller.syncNow(userId: 'user-1');

    expect(controller.state.status, SyncUiStatus.synced);
    expect(controller.state.lastSyncAt, DateTime(2026, 7, 1, 10));
    expect(controller.state.lastSyncResult, isA<LastSyncResult>());
    expect(controller.state.lastSyncResult, isNot(isA<AutoSyncResult>()));
    expect(controller.state.lastSyncResult!.uploadSynced, 1);
    expect(controller.state.lastSyncResult!.downloadApplied, 1);
  });

  test('syncNow exposes syncing while the coordinator is running', () async {
    final uploadCompleter = Completer<SyncOrchestrationResult>();
    final controller = SyncStatusController(
      coordinator: AutoSyncCoordinator.withRunners(
        runUpload: ({required userId}) => uploadCompleter.future,
        runDownload: ({required userId}) async => _downloadResult(),
      ),
      clock: () => DateTime(2026, 7, 1, 10),
    );

    final sync = controller.syncNow(userId: 'user-1');
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.status, SyncUiStatus.syncing);

    uploadCompleter.complete(_uploadResult());
    await sync;

    expect(controller.state.status, SyncUiStatus.synced);
  });

  test('pending and conflict counts come from sync metadata', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = LocalSyncMetadataRepository(database.syncMetadataDao);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    addTearDown(database.close);

    await repository.save(
      _metadata(
        id: 'sync-pending',
        localId: 'book-1',
        syncStatus: SyncStatus.pendingUpdate,
        pendingOperation: PendingSyncOperation.update,
      ),
    );
    await repository.save(
      _metadata(
        id: 'sync-conflict',
        localId: 'book-2',
        syncStatus: SyncStatus.pendingUpdate,
        pendingOperation: PendingSyncOperation.update,
      ),
    );
    await repository.markConflict(
      entityType: SyncEntityType.book,
      localId: 'book-2',
      remoteId: 'remote-book-2',
      lastRemoteUpdate: DateTime(2026, 7, 1, 12),
      message: 'Remote changed while local is pending.',
    );

    final summary = await container.read(syncMetadataSummaryProvider.future);

    expect(summary.pendingCount, 2);
    expect(summary.conflictCount, 1);
  });
}

SyncOrchestrationResult _uploadResult() {
  return const SyncOrchestrationResult(
    books: SyncPendingBooksResult(
      pendingBooks: 1,
      synced: 1,
      failed: 0,
      ignored: 0,
    ),
    readingSessions: SyncPendingReadingSessionsResult(
      pendingReadingSessions: 0,
      synced: 0,
      failed: 0,
      ignored: 0,
    ),
    readerProfile: SyncPendingReaderProfileResult(
      pendingReaderProfiles: 0,
      synced: 0,
      failed: 0,
      ignored: 0,
    ),
    annualGoal: SyncPendingAnnualGoalResult(
      pendingAnnualGoals: 0,
      synced: 0,
      failed: 0,
      ignored: 0,
    ),
  );
}

SyncDownloadOrchestrationResult _downloadResult() {
  return const SyncDownloadOrchestrationResult(
    books: DownloadBooksResult(
      remoteBooks: 1,
      applied: 1,
      skipped: 0,
      conflicts: 0,
      failed: 0,
    ),
    readingSessions: DownloadReadingSessionsResult(
      remoteReadingSessions: 0,
      applied: 0,
      skipped: 0,
      conflicts: 0,
      failed: 0,
    ),
    readerProfile: DownloadReaderProfileResult(
      remoteProfiles: 0,
      applied: 0,
      skipped: 0,
      conflicts: 0,
      failed: 0,
    ),
    annualGoal: DownloadAnnualGoalResult(
      remoteAnnualGoals: 0,
      applied: 0,
      skipped: 0,
      conflicts: 0,
      failed: 0,
    ),
  );
}

SyncMetadata _metadata({
  required String id,
  required String localId,
  required SyncStatus syncStatus,
  required PendingSyncOperation pendingOperation,
}) {
  final now = DateTime(2026, 7);
  return SyncMetadata(
    id: id,
    entityType: SyncEntityType.book,
    localId: localId,
    syncStatus: syncStatus,
    pendingOperation: pendingOperation,
    createdAt: now,
    updatedAt: now,
  );
}
