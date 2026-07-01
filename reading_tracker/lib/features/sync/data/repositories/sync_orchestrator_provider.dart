import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/sync_orchestrator.dart';
import 'manual_annual_goal_sync_provider.dart';
import 'manual_books_sync_provider.dart';
import 'manual_reader_profile_sync_provider.dart';
import 'manual_reading_sessions_sync_provider.dart';

final syncOrchestratorProvider = Provider<SyncOrchestrator?>((ref) {
  final syncBooks = ref.watch(syncPendingBooksToSupabaseProvider);
  if (syncBooks == null) return null;

  final syncReadingSessions = ref.watch(
    syncPendingReadingSessionsToSupabaseProvider,
  );
  if (syncReadingSessions == null) return null;

  final syncReaderProfile = ref.watch(
    syncPendingReaderProfileToSupabaseProvider,
  );
  if (syncReaderProfile == null) return null;

  final syncAnnualGoal = ref.watch(syncPendingAnnualGoalToSupabaseProvider);
  if (syncAnnualGoal == null) return null;

  return SyncOrchestrator(
    syncBooks: syncBooks,
    syncReadingSessions: syncReadingSessions,
    syncReaderProfile: syncReaderProfile,
    syncAnnualGoal: syncAnnualGoal,
  );
});
