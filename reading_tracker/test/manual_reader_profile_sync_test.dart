import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/core/preferences/reader_profile_controller.dart';
import 'package:reading_tracker/features/sync/domain/entities/remote_profile.dart';
import 'package:reading_tracker/features/sync/domain/entities/sync_metadata.dart';
import 'package:reading_tracker/features/sync/domain/repositories/remote_profile_repository.dart';
import 'package:reading_tracker/features/sync/domain/repositories/sync_metadata_repository.dart';
import 'package:reading_tracker/features/sync/domain/services/local_sync_tracker.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_reader_profile_to_supabase.dart';

void main() {
  const userId = 'user-1';

  test('update uploads reader profile and marks metadata as synced', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _profileMetadata(operation: PendingSyncOperation.update),
    ]);
    final remoteRepository = FakeRemoteProfileRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
      profile: const ReaderProfile(
        name: 'Patricia',
        greetingPreference: ReaderGreetingPreference.custom,
        customGreeting: 'Hola',
        currentReadingBookId: 'book-1',
      ),
    );

    final result = await useCase(userId: userId);

    expect(result.pendingReaderProfiles, 1);
    expect(result.synced, 1);
    expect(result.failed, 0);
    expect(remoteRepository.upserted.single.id, userId);
    expect(remoteRepository.upserted.single.readerName, 'Patricia');
    expect(remoteRepository.upserted.single.greeting, 'custom');
    expect(remoteRepository.upserted.single.customGreeting, 'Hola');
    expect(remoteRepository.upserted.single.createdAt, DateTime(2026, 7, 1));
    expect(remoteRepository.upserted.single.updatedAt, DateTime(2026, 7, 1));
    expect(
      metadataRepository.syncedRemoteIds[LocalSyncTracker.readerProfileLocalId],
      userId,
    );
  });

  test('create saves remote id as user id', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _profileMetadata(operation: PendingSyncOperation.create),
    ]);
    final remoteRepository = FakeRemoteProfileRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 1);
    expect(
      metadataRepository.syncedRemoteIds[LocalSyncTracker.readerProfileLocalId],
      userId,
    );
  });

  test(
    'delete with remote id deletes remote profile and marks synced',
    () async {
      final metadataRepository = FakeSyncMetadataRepository([
        _profileMetadata(
          remoteId: userId,
          operation: PendingSyncOperation.delete,
        ),
      ]);
      final remoteRepository = FakeRemoteProfileRepository();
      final useCase = _useCase(
        metadataRepository: metadataRepository,
        remoteRepository: remoteRepository,
      );

      final result = await useCase(userId: userId);

      expect(result.synced, 1);
      expect(remoteRepository.deletedUserIds, [userId]);
      expect(metadataRepository.syncedLocalIds, [
        LocalSyncTracker.readerProfileLocalId,
      ]);
    },
  );

  test('delete without remote id marks synced without remote delete', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _profileMetadata(operation: PendingSyncOperation.delete),
    ]);
    final remoteRepository = FakeRemoteProfileRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
    );

    final result = await useCase(userId: userId);

    expect(result.synced, 1);
    expect(remoteRepository.deletedUserIds, isEmpty);
    expect(metadataRepository.syncedLocalIds, [
      LocalSyncTracker.readerProfileLocalId,
    ]);
  });

  test('remote failure registers error and does not mark synced', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _profileMetadata(operation: PendingSyncOperation.update),
    ]);
    final remoteRepository = FakeRemoteProfileRepository(
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
      metadataRepository.failures[LocalSyncTracker.readerProfileLocalId],
      contains('Supabase'),
    );
  });

  test('ignores metadata that is not reader profile', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _metadata(
        entityType: SyncEntityType.book,
        localId: 'book-1',
        operation: PendingSyncOperation.create,
      ),
      _profileMetadata(operation: PendingSyncOperation.update),
    ]);
    final remoteRepository = FakeRemoteProfileRepository();
    final useCase = _useCase(
      metadataRepository: metadataRepository,
      remoteRepository: remoteRepository,
    );

    final result = await useCase(userId: userId);

    expect(result.pendingReaderProfiles, 1);
    expect(result.ignored, 1);
    expect(result.synced, 1);
  });
}

SyncPendingReaderProfileToSupabase _useCase({
  required FakeSyncMetadataRepository metadataRepository,
  required FakeRemoteProfileRepository remoteRepository,
  ReaderProfile profile = const ReaderProfile(
    name: 'Patricia',
    greetingPreference: ReaderGreetingPreference.female,
    customGreeting: '',
    currentReadingBookId: 'book-1',
  ),
}) {
  return SyncPendingReaderProfileToSupabase(
    metadataRepository: metadataRepository,
    remoteProfileRepository: remoteRepository,
    loadProfile: () async => profile,
  );
}

SyncMetadata _profileMetadata({
  String? remoteId,
  required PendingSyncOperation operation,
}) {
  return _metadata(
    entityType: SyncEntityType.profile,
    localId: LocalSyncTracker.readerProfileLocalId,
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

class FakeRemoteProfileRepository implements RemoteProfileRepository {
  FakeRemoteProfileRepository({this.upsertError});

  final Object? upsertError;
  final List<RemoteProfile> upserted = [];
  final List<String> deletedUserIds = [];

  @override
  Future<void> deleteProfile(String userId) async {
    deletedUserIds.add(userId);
  }

  @override
  Future<RemoteProfile?> getProfile(String userId) async {
    return null;
  }

  @override
  Future<RemoteProfile> upsertProfile(RemoteProfile profile) async {
    final error = upsertError;
    if (error != null) throw error;

    upserted.add(profile);
    return profile;
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
  Future<void> markConflict({
    required SyncEntityType entityType,
    required String localId,
    required String remoteId,
    required DateTime lastRemoteUpdate,
    required String message,
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
