import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../stats/data/repositories/annual_reading_goal_repository_provider.dart';
import '../../domain/usecases/sync_pending_annual_goal_to_supabase.dart';
import 'remote_annual_goals_repository_provider.dart';
import 'sync_metadata_repository_provider.dart';

final syncPendingAnnualGoalToSupabaseProvider =
    Provider<SyncPendingAnnualGoalToSupabase?>((ref) {
      final remoteAnnualGoalsRepository = ref.watch(
        remoteAnnualGoalsRepositoryProvider,
      );
      if (remoteAnnualGoalsRepository == null) return null;

      final annualGoalRepository = ref.watch(
        annualReadingGoalRepositoryProvider,
      );

      return SyncPendingAnnualGoalToSupabase(
        metadataRepository: ref.watch(syncMetadataRepositoryProvider),
        remoteAnnualGoalsRepository: remoteAnnualGoalsRepository,
        loadAnnualGoal: annualGoalRepository.getAnnualReadingGoal,
      );
    });
