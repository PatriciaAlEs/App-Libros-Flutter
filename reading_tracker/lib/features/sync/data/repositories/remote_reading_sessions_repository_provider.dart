import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/remote_reading_sessions_repository.dart';
import '../datasources/supabase_remote_sync_datasource.dart';
import 'supabase_remote_reading_sessions_repository.dart';

final remoteReadingSessionsRepositoryProvider =
    Provider<RemoteReadingSessionsRepository?>((ref) {
      final datasource = ref.watch(remoteSyncDatasourceProvider);
      if (datasource == null) return null;
      return SupabaseRemoteReadingSessionsRepository(datasource);
    });
