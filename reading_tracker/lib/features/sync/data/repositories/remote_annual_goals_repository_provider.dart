import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/remote_annual_goals_repository.dart';
import '../datasources/supabase_remote_sync_datasource.dart';
import 'supabase_remote_annual_goals_repository.dart';

final remoteAnnualGoalsRepositoryProvider =
    Provider<RemoteAnnualGoalsRepository?>((ref) {
      final datasource = ref.watch(remoteSyncDatasourceProvider);
      if (datasource == null) return null;

      return SupabaseRemoteAnnualGoalsRepository(datasource);
    });
