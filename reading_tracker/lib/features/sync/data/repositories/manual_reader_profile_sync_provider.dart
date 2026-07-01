import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/preferences/reader_profile_controller.dart';
import '../../domain/usecases/sync_pending_reader_profile_to_supabase.dart';
import 'remote_profile_repository_provider.dart';
import 'sync_metadata_repository_provider.dart';

final syncPendingReaderProfileToSupabaseProvider =
    Provider<SyncPendingReaderProfileToSupabase?>((ref) {
      final remoteProfileRepository = ref.watch(
        remoteProfileRepositoryProvider,
      );
      if (remoteProfileRepository == null) return null;

      return SyncPendingReaderProfileToSupabase(
        metadataRepository: ref.watch(syncMetadataRepositoryProvider),
        remoteProfileRepository: remoteProfileRepository,
        loadProfile: ReaderProfilePreferences.load,
      );
    });
