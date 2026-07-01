import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/sync/domain/entities/remote_annual_goal.dart';
import 'package:reading_tracker/features/sync/domain/entities/sync_metadata.dart';
import 'package:reading_tracker/features/sync/domain/repositories/remote_annual_goals_repository.dart';
import 'package:reading_tracker/features/sync/domain/repositories/sync_metadata_repository.dart';
import 'package:reading_tracker/features/sync/domain/services/local_sync_tracker.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_annual_goal_to_supabase.dart';

void main() {
  const userId = 'user-1';

  test('update uploads annual goal and marks metadata as synced', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _annualGoalMetadata(operation: PendingSyncOperation.update),
    ]);
    final remoteRepository = FakeRemoteAnnualGoalsRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
      annualGoal: 42,
    );

    final result = await useCase(userId: userId);

    expect(result.pendingAnnualGoals, 1);
    expect(result.synced, 1);
    expect(result.failed, 0);
    expect(remoteRepository.upserted.single.id, 'generated-goal-1');
    expect(remoteRepository.upserted.single.userId, userId);
    expect(
      remoteRepository.upserted.single.localGoalId,
      LocalSyncTracker.annualGoalLocalId,
    );
    expect(remoteRepository.upserted.single.year, 2026);
    expect(remoteRepository.upserted.single.targetBooks, 42);
    expect(
      metadataRepository.syncedRemoteIds[LocalSyncTracker.annualGoalLocalId],
      'returned-goal-1',
    );
  });

  test('create saves returned remote id', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _annualGoalMetadata(operation: PendingSyncOperation.create),
    ]);
    final remoteRepository = FakeRemoteAnnualGoalsRepository(
      returnedRemoteId: 'supabase-goal-1',
    );
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 1);
    expect(
      metadataRepository.syncedRemoteIds[LocalSyncTracker.annualGoalLocalId],
      'supabase-goal-1',
    );
  });

  test('reuses existing remote id and injected clock year', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _annualGoalMetadata(
        remoteId: 'existing-goal-1',
        operation: PendingSyncOperation.update,
      ),
    ]);
    final remoteRepository = FakeRemoteAnnualGoalsRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
      clock: () => DateTime(2030, 1),
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 1);
    expect(remoteRepository.upserted.single.id, 'existing-goal-1');
    expect(remoteRepository.upserted.single.year, 2030);
  });

  test('delete with remote id deletes remote goal and marks synced', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _annualGoalMetadata(
        remoteId: 'remote-goal-1',
        operation: PendingSyncOperation.delete,
      ),
    ]);
    final remoteRepository = FakeRemoteAnnualGoalsRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 1);
    expect(remoteRepository.deletedGoalIds, ['remote-goal-1']);
    expect(metadataRepository.syncedLocalIds, [
      LocalSyncTracker.annualGoalLocalId,
    ]);
  });

  test('delete without remote id marks synced without remote delete', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _annualGoalMetadata(operation: PendingSyncOperation.delete),
    ]);
    final remoteRepository = FakeRemoteAnnualGoalsRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 1);
    expect(remoteRepository.deletedGoalIds, isEmpty);
    expect(metadataRepository.syncedLocalIds, [
      LocalSyncTracker.annualGoalLocalId,
    ]);
  });

  test('null local goal registers failure and does not mark synced', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _annualGoalMetadata(operation: PendingSyncOperation.update),
    ]);
    final remoteRepository = FakeRemoteAnnualGoalsRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
      annualGoal: null,
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 0);
    expect(result.failed, 1);
    expect(remoteRepository.upserted, isEmpty);
    expect(metadataRepository.syncedLocalIds, isEmpty);
    expect(
      metadataRepository.failures[LocalSyncTracker.annualGoalLocalId],
      contains('Local annual goal not found'),
    );
  });

  test('remote failure registers error and does not mark synced', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _annualGoalMetadata(operation: PendingSyncOperation.update),
    ]);
    final remoteRepository = FakeRemoteAnnualGoalsRepository(
      upsertError: Exception('Supabase is unavailable'),
    );
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 0);
    expect(result.failed, 1);
    expect(metadataRepository.syncedLocalIds, isEmpty);
    expect(
      metadataRepository.failures[LocalSyncTracker.annualGoalLocalId],
      contains('Supabase'),
    );
  });

  test('ignores metadata that is not annual goal', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _metadata(
        entityType: SyncEntityType.book,
        localId: 'book-1',
        operation: PendingSyncOperation.create,
      ),
      _annualGoalMetadata(operation: PendingSyncOperation.update),
    ]);
    final remoteRepository = FakeRemoteAnnualGoalsRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
    );

    final result = await useCase(userId: userId);

    expect(result.pendingAnnualGoals, 1);
    expect(result.ignored, 1);
    expect(result.synced, 1);
  });
}

SyncPendingAnnualGoalToSupabase _useCase({
  required FakeSyncMetadataRepository metadataRepository,
  required FakeRemoteAnnualGoalsRepository remoteRepository,
  int? annualGoal = 24,
  DateTime Function()? clock,
}) {
  return SyncPendingAnnualGoalToSupabase(
    metadataRepository: metadataRepository,
    remoteAnnualGoalsRepository: remoteRepository,
    loadAnnualGoal: () async => annualGoal,
    remoteIdGenerator: () => 'generated-goal-1',
    clock: clock ?? () => DateTime(2026, 7),
  );
}

SyncMetadata _annualGoalMetadata({
  String? remoteId,
  required PendingSyncOperation operation,
}) {
  return _metadata(
    entityType: SyncEntityType.annualGoal,
    localId: LocalSyncTracker.annualGoalLocalId,
    remoteId: remoteId,
    operation: operation,
  );
}

SyncMetadata _metadata({
  required SyncEntityType entityType,
  required String localId,
  String? remoteId,
  required PendingSyncOperation operation,
}) {
  final now = DateTime(2026, 7, 1);
  return SyncMetadata(
    id: 'sync-$localId',
    entityType: entityType,
    localId: localId,
    remoteId: remoteId,
    syncStatus: switch (operation) {
      PendingSyncOperation.create => SyncStatus.pendingUpload,
      PendingSyncOperation.update => SyncStatus.pendingUpdate,
      PendingSyncOperation.delete => SyncStatus.pendingDelete,
      PendingSyncOperation.none => SyncStatus.synced,
    },
    pendingOperation: operation,
    createdAt: now,
    updatedAt: now,
  );
}

class FakeRemoteAnnualGoalsRepository implements RemoteAnnualGoalsRepository {
  FakeRemoteAnnualGoalsRepository({
    this.returnedRemoteId = 'returned-goal-1',
    this.upsertError,
  });

  final String returnedRemoteId;
  final Object? upsertError;
  final List<RemoteAnnualGoal> upserted = [];
  final List<String> deletedGoalIds = [];

  @override
  Future<void> deleteAnnualGoal({
    required String userId,
    required String goalId,
  }) async {
    deletedGoalIds.add(goalId);
  }

  @override
  Future<List<RemoteAnnualGoal>> getAnnualGoals({
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  }) async {
    return const [];
  }

  @override
  Future<List<RemoteAnnualGoal>> upsertAnnualGoals(
    List<RemoteAnnualGoal> goals,
  ) async {
    final error = upsertError;
    if (error != null) throw error;

    final goal = goals.single;
    upserted.add(goal);
    return [
      RemoteAnnualGoal(
        id: returnedRemoteId,
        userId: goal.userId,
        localGoalId: goal.localGoalId,
        year: goal.year,
        targetBooks: goal.targetBooks,
        updatedAt: DateTime(2026, 7, 2),
      ),
    ];
  }
}

class FakeSyncMetadataRepository implements SyncMetadataRepository {
  FakeSyncMetadataRepository(this.metadata);

  final List<SyncMetadata> metadata;
  final List<String> syncedLocalIds = [];
  final Map<String, String?> syncedRemoteIds = {};
  final Map<String, String> failures = {};

  @override
  Future<void> associateRemoteId({
    required SyncEntityType entityType,
    required String localId,
    required String remoteId,
    DateTime? lastRemoteUpdate,
  }) async {}

  @override
  Future<SyncMetadata?> getByLocalId({
    required SyncEntityType entityType,
    required String localId,
  }) async {
    return null;
  }

  @override
  Future<List<SyncMetadata>> getPendingSync() async {
    return metadata.where((item) => item.hasPendingOperation).toList();
  }

  @override
  Future<void> markPendingDelete({
    required SyncEntityType entityType,
    required String localId,
    DateTime? localUpdate,
  }) async {}

  @override
  Future<void> markPendingUpdate({
    required SyncEntityType entityType,
    required String localId,
    DateTime? localUpdate,
  }) async {}

  @override
  Future<void> markPendingUpload({
    required SyncEntityType entityType,
    required String localId,
    DateTime? localUpdate,
  }) async {}

  @override
  Future<void> markSynced({
    required SyncEntityType entityType,
    required String localId,
    String? remoteId,
    DateTime? lastRemoteUpdate,
  }) async {
    syncedLocalIds.add(localId);
    syncedRemoteIds[localId] = remoteId;
  }

  @override
  Future<void> registerFailure({
    required SyncEntityType entityType,
    required String localId,
    required String message,
  }) async {
    failures[localId] = message;
  }

  @override
  Future<void> save(SyncMetadata metadata) async {}
}
