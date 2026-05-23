import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_tracker/core/database/database_provider.dart';
import 'package:reading_tracker/features/stats/domain/repositories/annual_reading_goal_repository.dart';

import 'drift_annual_reading_goal_repository.dart';

final annualReadingGoalRepositoryProvider =
    Provider<AnnualReadingGoalRepository>((ref) {
      return DriftAnnualReadingGoalRepository(ref.watch(databaseProvider));
    });
