import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/preferences/reader_profile_controller.dart';
import '../../domain/usecases/download_reader_profile_from_supabase.dart';
import 'remote_profile_repository_provider.dart';
import 'sync_metadata_repository_provider.dart';

final downloadReaderProfileFromSupabaseProvider =
    Provider<DownloadReaderProfileFromSupabase?>((ref) {
      final remoteProfileRepository = ref.watch(
        remoteProfileRepositoryProvider,
      );
      if (remoteProfileRepository == null) return null;

      return DownloadReaderProfileFromSupabase(
        remoteProfileRepository: remoteProfileRepository,
        metadataRepository: ref.watch(syncMetadataRepositoryProvider),
        readLocalProfile: ReaderProfilePreferences.load,
        writeLocalProfile: ReaderProfilePreferences.saveSyncedProfile,
      );
    });
