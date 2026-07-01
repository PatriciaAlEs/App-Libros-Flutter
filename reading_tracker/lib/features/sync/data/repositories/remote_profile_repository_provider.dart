import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/remote_profile_repository.dart';
import '../datasources/supabase_remote_sync_datasource.dart';
import 'supabase_remote_profile_repository.dart';

final remoteProfileRepositoryProvider = Provider<RemoteProfileRepository?>((
  ref,
) {
  final datasource = ref.watch(remoteSyncDatasourceProvider);
  if (datasource == null) return null;
  return SupabaseRemoteProfileRepository(datasource);
});
