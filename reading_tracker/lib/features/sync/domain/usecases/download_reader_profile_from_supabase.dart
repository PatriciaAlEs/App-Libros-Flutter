import '../../../../core/preferences/reader_profile_controller.dart';
import '../entities/remote_profile.dart';
import '../entities/sync_metadata.dart';
import '../repositories/remote_profile_repository.dart';
import '../repositories/sync_metadata_repository.dart';
import '../services/local_sync_tracker.dart';

typedef LocalReaderProfileReader = Future<ReaderProfile> Function();
typedef LocalReaderProfileWriter = Future<void> Function(ReaderProfile profile);

class DownloadReaderProfileResult {
  const DownloadReaderProfileResult({
    required this.remoteProfiles,
    required this.applied,
    required this.skipped,
    required this.failed,
  });

  final int remoteProfiles;
  final int applied;
  final int skipped;
  final int failed;
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
        failed: 0,
      );
    }

    if (remoteProfile.deletedAt != null) {
      return const DownloadReaderProfileResult(
        remoteProfiles: 1,
        applied: 0,
        skipped: 1,
        failed: 0,
      );
    }

    try {
      final metadata = await _metadataRepository.getByLocalId(
        entityType: SyncEntityType.profile,
        localId: LocalSyncTracker.readerProfileLocalId,
      );
      if (metadata?.hasPendingOperation ?? false) {
        return const DownloadReaderProfileResult(
          remoteProfiles: 1,
          applied: 0,
          skipped: 1,
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
        failed: 0,
      );
    } catch (_) {
      return const DownloadReaderProfileResult(
        remoteProfiles: 1,
        applied: 0,
        skipped: 0,
        failed: 1,
      );
    }
  }
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
