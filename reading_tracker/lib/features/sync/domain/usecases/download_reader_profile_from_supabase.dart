import '../../../../core/preferences/reader_profile_controller.dart';
import '../entities/remote_profile.dart';
import '../entities/sync_metadata.dart';
import '../repositories/remote_profile_repository.dart';
import '../repositories/sync_metadata_repository.dart';
import '../services/local_sync_tracker.dart';
import '../services/sync_debug_logger.dart';

typedef LocalReaderProfileReader = Future<ReaderProfile> Function();
typedef LocalReaderProfileWriter = Future<void> Function(ReaderProfile profile);

class DownloadReaderProfileResult {
  const DownloadReaderProfileResult({
    required this.remoteProfiles,
    required this.applied,
    required this.skipped,
    required this.conflicts,
    required this.failed,
    this.failureMessages = const [],
  });

  final int remoteProfiles;
  final int applied;
  final int skipped;
  final int conflicts;
  final int failed;
  final List<String> failureMessages;
}

class DownloadReaderProfileFromSupabase {
  const DownloadReaderProfileFromSupabase({
    required RemoteProfileRepository remoteProfileRepository,
    required SyncMetadataRepository metadataRepository,
    required LocalReaderProfileReader readLocalProfile,
    required LocalReaderProfileWriter writeLocalProfile,
  }) : _remoteProfileRepository = remoteProfileRepository,
       _metadataRepository = metadataRepository,
       _readLocalProfile = readLocalProfile,
       _writeLocalProfile = writeLocalProfile;

  final RemoteProfileRepository _remoteProfileRepository;
  final SyncMetadataRepository _metadataRepository;
  final LocalReaderProfileReader _readLocalProfile;
  final LocalReaderProfileWriter _writeLocalProfile;

  Future<DownloadReaderProfileResult> call({required String userId}) async {
    final remoteProfile = await _remoteProfileRepository.getProfile(userId);
    if (remoteProfile == null) {
      return const DownloadReaderProfileResult(
        remoteProfiles: 0,
        applied: 0,
        skipped: 0,
        conflicts: 0,
        failed: 0,
      );
    }

    if (remoteProfile.deletedAt != null) {
      return const DownloadReaderProfileResult(
        remoteProfiles: 1,
        applied: 0,
        skipped: 1,
        conflicts: 0,
        failed: 0,
      );
    }

    try {
      final metadata = await _metadataRepository.getByLocalId(
        entityType: SyncEntityType.profile,
        localId: LocalSyncTracker.readerProfileLocalId,
      );
      if (metadata?.hasPendingOperation ?? false) {
        if (_hasNewerRemoteVersion(metadata!, remoteProfile.updatedAt)) {
          await _metadataRepository.markConflict(
            entityType: SyncEntityType.profile,
            localId: LocalSyncTracker.readerProfileLocalId,
            remoteId: remoteProfile.id,
            lastRemoteUpdate: remoteProfile.updatedAt!,
            message: _conflictMessage(
              entityType: SyncEntityType.profile,
              localId: LocalSyncTracker.readerProfileLocalId,
              remoteId: remoteProfile.id,
              remoteUpdatedAt: remoteProfile.updatedAt!,
            ),
          );
          return const DownloadReaderProfileResult(
            remoteProfiles: 1,
            applied: 0,
            skipped: 0,
            conflicts: 1,
            failed: 0,
          );
        }
        return const DownloadReaderProfileResult(
          remoteProfiles: 1,
          applied: 0,
          skipped: 1,
          conflicts: 0,
          failed: 0,
        );
      }

      final localProfile = await _readLocalProfile();
      await _writeLocalProfile(_profileFromRemote(remoteProfile, localProfile));
      await _metadataRepository.markSynced(
        entityType: SyncEntityType.profile,
        localId: LocalSyncTracker.readerProfileLocalId,
        remoteId: remoteProfile.id,
        lastRemoteUpdate: remoteProfile.updatedAt,
      );
      return const DownloadReaderProfileResult(
        remoteProfiles: 1,
        applied: 1,
        skipped: 0,
        conflicts: 0,
        failed: 0,
      );
    } catch (error, stackTrace) {
      final message = syncFailureMessage(
        operation: 'download',
        entityType: SyncEntityType.profile.value,
        localId: LocalSyncTracker.readerProfileLocalId,
        table: 'profiles',
        error: error,
      );
      logSyncDebugError(
        operation: 'download',
        entityType: SyncEntityType.profile.value,
        localId: LocalSyncTracker.readerProfileLocalId,
        userId: userId,
        table: 'profiles',
        error: error,
        stackTrace: stackTrace,
      );
      return DownloadReaderProfileResult(
        remoteProfiles: 1,
        applied: 0,
        skipped: 0,
        conflicts: 0,
        failed: 1,
        failureMessages: [message],
      );
    }
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

ReaderProfile _profileFromRemote(
  RemoteProfile remoteProfile,
  ReaderProfile localProfile,
) {
  return localProfile.copyWith(
    name: remoteProfile.readerName ?? '',
    greetingPreference: ReaderGreetingPreference.fromName(
      remoteProfile.greeting,
    ),
    customGreeting: remoteProfile.customGreeting ?? '',
  );
}
