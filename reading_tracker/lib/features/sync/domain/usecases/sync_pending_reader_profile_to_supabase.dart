import '../../../../core/preferences/reader_profile_controller.dart';
import '../entities/remote_profile.dart';
import '../entities/sync_metadata.dart';
import '../repositories/remote_profile_repository.dart';
import '../repositories/sync_metadata_repository.dart';
import '../services/sync_debug_logger.dart';

typedef LocalReaderProfileLoader = Future<ReaderProfile> Function();

class SyncPendingReaderProfileResult {
  const SyncPendingReaderProfileResult({
    required this.pendingReaderProfiles,
    required this.synced,
    required this.failed,
    required this.ignored,
    this.failureMessages = const [],
  });

  final int pendingReaderProfiles;
  final int synced;
  final int failed;
  final int ignored;
  final List<String> failureMessages;
}

class SyncPendingReaderProfileToSupabase {
  const SyncPendingReaderProfileToSupabase({
    required SyncMetadataRepository metadataRepository,
    required RemoteProfileRepository remoteProfileRepository,
    required LocalReaderProfileLoader loadProfile,
  }) : _metadataRepository = metadataRepository,
       _remoteProfileRepository = remoteProfileRepository,
       _loadProfile = loadProfile;

  final SyncMetadataRepository _metadataRepository;
  final RemoteProfileRepository _remoteProfileRepository;
  final LocalReaderProfileLoader _loadProfile;

  Future<SyncPendingReaderProfileResult> call({required String userId}) async {
    final pending = await _metadataRepository.getPendingSync();
    final pendingReaderProfiles = pending
        .where((metadata) => metadata.entityType == SyncEntityType.profile)
        .toList();

    var synced = 0;
    var failed = 0;
    final failureMessages = <String>[];

    for (final metadata in pendingReaderProfiles) {
      try {
        switch (metadata.pendingOperation) {
          case PendingSyncOperation.create:
          case PendingSyncOperation.update:
            await _syncProfileUpsert(metadata: metadata, userId: userId);
            synced++;
            break;
          case PendingSyncOperation.delete:
            await _syncProfileDelete(metadata: metadata, userId: userId);
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
          table: 'profiles',
          error: error,
        );
        failed++;
        failureMessages.add(message);
        logSyncDebugError(
          operation: metadata.pendingOperation.value,
          entityType: metadata.entityType.value,
          localId: metadata.localId,
          userId: userId,
          table: 'profiles',
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

    return SyncPendingReaderProfileResult(
      pendingReaderProfiles: pendingReaderProfiles.length,
      synced: synced,
      failed: failed,
      ignored: pending.length - pendingReaderProfiles.length,
      failureMessages: failureMessages,
    );
  }

  Future<void> _syncProfileUpsert({
    required SyncMetadata metadata,
    required String userId,
  }) async {
    final profile = await _loadProfile();
    final remoteProfile = _remoteProfileFromLocal(profile, userId: userId);
    final syncedProfile = await _remoteProfileRepository.upsertProfile(
      remoteProfile,
    );

    await _metadataRepository.markSynced(
      entityType: metadata.entityType,
      localId: metadata.localId,
      remoteId: syncedProfile.id,
      lastRemoteUpdate: syncedProfile.updatedAt,
    );
  }

  Future<void> _syncProfileDelete({
    required SyncMetadata metadata,
    required String userId,
  }) async {
    final remoteId = metadata.remoteId;

    if (remoteId != null) {
      await _remoteProfileRepository.deleteProfile(remoteId);
    }

    await _metadataRepository.markSynced(
      entityType: metadata.entityType,
      localId: metadata.localId,
      remoteId: remoteId,
    );
  }
}

RemoteProfile _remoteProfileFromLocal(
  ReaderProfile profile, {
  required String userId,
}) {
  final readerName = profile.displayName;
  final customGreeting = profile.customGreeting.trim();

  return RemoteProfile(
    id: userId,
    readerName: readerName.isEmpty ? null : readerName,
    greeting: profile.greetingPreference.name,
    customGreeting: customGreeting.isEmpty ? null : customGreeting,
  );
}
