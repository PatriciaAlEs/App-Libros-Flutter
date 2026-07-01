import '../usecases/download_annual_goal_from_supabase.dart';
import '../usecases/download_books_from_supabase.dart';
import '../usecases/download_reader_profile_from_supabase.dart';
import '../usecases/download_reading_sessions_from_supabase.dart';
import '../usecases/sync_pending_books_to_supabase.dart';
import '../usecases/sync_pending_reading_sessions_to_supabase.dart';
import '../usecases/sync_pending_reader_profile_to_supabase.dart';
import '../usecases/sync_pending_annual_goal_to_supabase.dart';

class SyncOrchestrationResult {
  const SyncOrchestrationResult({
    required this.books,
    required this.readingSessions,
    required this.readerProfile,
    required this.annualGoal,
  });

  final SyncPendingBooksResult books;
  final SyncPendingReadingSessionsResult readingSessions;
  final SyncPendingReaderProfileResult readerProfile;
  final SyncPendingAnnualGoalResult annualGoal;

  int get synced =>
      books.synced +
      readingSessions.synced +
      readerProfile.synced +
      annualGoal.synced;
  int get failed =>
      books.failed +
      readingSessions.failed +
      readerProfile.failed +
      annualGoal.failed;
  int get ignored =>
      books.ignored +
      readingSessions.ignored +
      readerProfile.ignored +
      annualGoal.ignored;
}

class SyncDownloadOrchestrationResult {
  const SyncDownloadOrchestrationResult({
    required this.books,
    required this.readingSessions,
    required this.readerProfile,
    required this.annualGoal,
  });

  final DownloadBooksResult books;
  final DownloadReadingSessionsResult readingSessions;
  final DownloadReaderProfileResult readerProfile;
  final DownloadAnnualGoalResult annualGoal;

  int get applied =>
      books.applied +
      readingSessions.applied +
      readerProfile.applied +
      annualGoal.applied;
  int get skipped =>
      books.skipped +
      readingSessions.skipped +
      readerProfile.skipped +
      annualGoal.skipped;
  int get conflicts =>
      books.conflicts +
      readingSessions.conflicts +
      readerProfile.conflicts +
      annualGoal.conflicts;
  int get failed =>
      books.failed +
      readingSessions.failed +
      readerProfile.failed +
      annualGoal.failed;
}

class SyncOrchestrator {
  const SyncOrchestrator({
    required SyncPendingBooksToSupabase syncBooks,
    required SyncPendingReadingSessionsToSupabase syncReadingSessions,
    required SyncPendingReaderProfileToSupabase syncReaderProfile,
    required SyncPendingAnnualGoalToSupabase syncAnnualGoal,
    required DownloadBooksFromSupabase downloadBooks,
    required DownloadReadingSessionsFromSupabase downloadReadingSessions,
    required DownloadReaderProfileFromSupabase downloadReaderProfile,
    required DownloadAnnualGoalFromSupabase downloadAnnualGoal,
  }) : _syncBooks = syncBooks,
       _syncReadingSessions = syncReadingSessions,
       _syncReaderProfile = syncReaderProfile,
       _syncAnnualGoal = syncAnnualGoal,
       _downloadBooks = downloadBooks,
       _downloadReadingSessions = downloadReadingSessions,
       _downloadReaderProfile = downloadReaderProfile,
       _downloadAnnualGoal = downloadAnnualGoal;

  final SyncPendingBooksToSupabase _syncBooks;
  final SyncPendingReadingSessionsToSupabase _syncReadingSessions;
  final SyncPendingReaderProfileToSupabase _syncReaderProfile;
  final SyncPendingAnnualGoalToSupabase _syncAnnualGoal;
  final DownloadBooksFromSupabase _downloadBooks;
  final DownloadReadingSessionsFromSupabase _downloadReadingSessions;
  final DownloadReaderProfileFromSupabase _downloadReaderProfile;
  final DownloadAnnualGoalFromSupabase _downloadAnnualGoal;

  Future<SyncOrchestrationResult> runManualSync({
    required String userId,
  }) async {
    final books = await _syncBooks(userId: userId);
    final readingSessions = await _syncReadingSessions(userId: userId);
    final readerProfile = await _syncReaderProfile(userId: userId);
    final annualGoal = await _syncAnnualGoal(userId: userId);
    return SyncOrchestrationResult(
      books: books,
      readingSessions: readingSessions,
      readerProfile: readerProfile,
      annualGoal: annualGoal,
    );
  }

  Future<SyncDownloadOrchestrationResult> runManualDownload({
    required String userId,
  }) async {
    final books = await _downloadBooks(userId: userId);
    final readingSessions = await _downloadReadingSessions(userId: userId);
    final readerProfile = await _downloadReaderProfile(userId: userId);
    final annualGoal = await _downloadAnnualGoal(userId: userId);
    return SyncDownloadOrchestrationResult(
      books: books,
      readingSessions: readingSessions,
      readerProfile: readerProfile,
      annualGoal: annualGoal,
    );
  }
}
