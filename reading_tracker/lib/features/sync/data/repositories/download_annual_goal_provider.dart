import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../stats/data/repositories/annual_reading_goal_repository_provider.dart';
import '../../domain/usecases/download_annual_goal_from_supabase.dart';
import 'remote_annual_goals_repository_provider.dart';
import 'sync_metadata_repository_provider.dart';

final downloadAnnualGoalFromSupabaseProvider =
    Provider<DownloadAnnualGoalFromSupabase?>((ref) {
      final remoteAnnualGoalsRepository = ref.watch(
        remoteAnnualGoalsRepositoryProvider,
      );
      if (remoteAnnualGoalsRepository == null) return null;

      final annualGoalRepository = ref.watch(
        annualReadingGoalRepositoryProvider,
      );

      return DownloadAnnualGoalFromSupabase(
        remoteAnnualGoalsRepository: remoteAnnualGoalsRepository,
        metadataRepository: ref.watch(syncMetadataRepositoryProvider),
        writeAnnualGoal: annualGoalRepository.saveAnnualReadingGoal,
      );
    });
