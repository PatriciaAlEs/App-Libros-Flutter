import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/sync_orchestrator.dart';
import 'download_annual_goal_provider.dart';
import 'download_books_provider.dart';
import 'download_reader_profile_provider.dart';
import 'download_reading_sessions_provider.dart';
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

  final downloadBooks = ref.watch(downloadBooksFromSupabaseProvider);
  if (downloadBooks == null) return null;

  final downloadReadingSessions = ref.watch(
    downloadReadingSessionsFromSupabaseProvider,
  );
  if (downloadReadingSessions == null) return null;

  final downloadReaderProfile = ref.watch(
    downloadReaderProfileFromSupabaseProvider,
  );
  if (downloadReaderProfile == null) return null;

  final downloadAnnualGoal = ref.watch(downloadAnnualGoalFromSupabaseProvider);
  if (downloadAnnualGoal == null) return null;

  return SyncOrchestrator(
    syncBooks: syncBooks,
    syncReadingSessions: syncReadingSessions,
    syncReaderProfile: syncReaderProfile,
    syncAnnualGoal: syncAnnualGoal,
    downloadBooks: downloadBooks,
    downloadReadingSessions: downloadReadingSessions,
    downloadReaderProfile: downloadReaderProfile,
    downloadAnnualGoal: downloadAnnualGoal,
  );
});
