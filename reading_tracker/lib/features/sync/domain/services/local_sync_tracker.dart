import 'package:uuid/uuid.dart';

import '../entities/sync_metadata.dart';
import '../repositories/sync_metadata_repository.dart';

typedef SyncMetadataIdGenerator = String Function();
typedef SyncClock = DateTime Function();

class LocalSyncTracker {
  LocalSyncTracker(
    this._repository, {
    SyncMetadataIdGenerator? idGenerator,
    SyncClock? clock,
  }) : _idGenerator = idGenerator ?? const Uuid().v4,
       _clock = clock ?? DateTime.now;

  static const annualGoalLocalId = 'annualReadingGoal';
  static const readerProfileLocalId = 'reader_profile';

  final SyncMetadataRepository _repository;
  final SyncMetadataIdGenerator _idGenerator;
  final SyncClock _clock;

  Future<void> trackBookCreated(String localId) {
    return _trackCreated(SyncEntityType.book, localId);
  }

  Future<void> trackBookUpdated(String localId) {
    return _trackUpdated(SyncEntityType.book, localId);
  }

  Future<void> trackBookDeleted(String localId) {
    return _trackDeleted(SyncEntityType.book, localId);
  }

  Future<void> trackReadingSessionCreated(String localId) {
    return _trackCreated(SyncEntityType.readingSession, localId);
  }

  Future<void> trackReadingSessionUpdated(String localId) {
    return _trackUpdated(SyncEntityType.readingSession, localId);
  }

  Future<void> trackReadingSessionDeleted(String localId) {
    return _trackDeleted(SyncEntityType.readingSession, localId);
  }

  Future<void> trackAnnualGoalCreated() {
    return _trackCreated(SyncEntityType.annualGoal, annualGoalLocalId);
  }

  Future<void> trackAnnualGoalUpdated() {
    return _trackUpdated(SyncEntityType.annualGoal, annualGoalLocalId);
  }

  Future<void> trackProfileUpdated() {
    return _trackUpdated(SyncEntityType.profile, readerProfileLocalId);
  }

  Future<void> _trackCreated(SyncEntityType entityType, String localId) {
    return _track(
      entityType: entityType,
      localId: localId,
      syncStatus: SyncStatus.pendingUpload,
      pendingOperation: PendingSyncOperation.create,
    );
  }

  Future<void> _trackUpdated(SyncEntityType entityType, String localId) {
    return _track(
      entityType: entityType,
      localId: localId,
      syncStatus: SyncStatus.pendingUpdate,
      pendingOperation: PendingSyncOperation.update,
    );
  }

  Future<void> _trackDeleted(SyncEntityType entityType, String localId) {
    return _track(
      entityType: entityType,
      localId: localId,
      syncStatus: SyncStatus.pendingDelete,
      pendingOperation: PendingSyncOperation.delete,
    );
  }

  Future<void> _track({
    required SyncEntityType entityType,
    required String localId,
    required SyncStatus syncStatus,
    required PendingSyncOperation pendingOperation,
  }) async {
    final existing = await _repository.getByLocalId(
      entityType: entityType,
      localId: localId,
    );

    if (existing == null) {
      final now = _clock();
      await _repository.save(
        SyncMetadata(
          id: _idGenerator(),
          entityType: entityType,
          localId: localId,
          syncStatus: syncStatus,
          pendingOperation: pendingOperation,
          lastLocalUpdate: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
      return;
    }

    switch (pendingOperation) {
      case PendingSyncOperation.create:
        await _repository.markPendingUpload(
          entityType: entityType,
          localId: localId,
          localUpdate: _clock(),
        );
        break;
      case PendingSyncOperation.update:
        await _repository.markPendingUpdate(
          entityType: entityType,
          localId: localId,
          localUpdate: _clock(),
        );
        break;
      case PendingSyncOperation.delete:
        await _repository.markPendingDelete(
          entityType: entityType,
          localId: localId,
          localUpdate: _clock(),
        );
        break;
      case PendingSyncOperation.none:
        break;
    }
  }
}
