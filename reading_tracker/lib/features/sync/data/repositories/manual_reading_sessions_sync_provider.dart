import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../reading_sessions/data/mappers/reading_session_mapper.dart';
import '../../domain/usecases/sync_pending_reading_sessions_to_supabase.dart';
import 'remote_reading_sessions_repository_provider.dart';
import 'sync_metadata_repository_provider.dart';

final syncPendingReadingSessionsToSupabaseProvider =
    Provider<SyncPendingReadingSessionsToSupabase?>((ref) {
      final remoteReadingSessionsRepository = ref.watch(
        remoteReadingSessionsRepositoryProvider,
      );
      if (remoteReadingSessionsRepository == null) return null;

      final database = ref.watch(databaseProvider);

      return SyncPendingReadingSessionsToSupabase(
        metadataRepository: ref.watch(syncMetadataRepositoryProvider),
        remoteReadingSessionsRepository: remoteReadingSessionsRepository,
        loadSession: (localId) async {
          final row = await database.readingSessionDao.getSessionById(localId);
          return row?.toDomain();
        },
      );
    });
