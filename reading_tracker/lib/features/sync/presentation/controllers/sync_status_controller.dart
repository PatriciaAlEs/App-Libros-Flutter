import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/preferences/reader_profile_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../books/presentation/providers/books_provider.dart';
import '../../../insights/presentation/providers/reading_insights_summary_provider.dart';
import '../../../reading_sessions/presentation/providers/reading_sessions_provider.dart';
import '../../../stats/presentation/providers/statistics_summary_provider.dart';
import '../../data/repositories/auto_sync_coordinator_provider.dart';
import '../../data/repositories/sync_metadata_summary_provider.dart';
import '../../domain/entities/sync_status_state.dart';
import '../../domain/services/auto_sync_coordinator.dart';

final syncStatusControllerProvider =
    StateNotifierProvider<SyncStatusController, SyncStatusState>((ref) {
      return SyncStatusController(
        coordinator: ref.watch(autoSyncCoordinatorProvider),
        clock: DateTime.now,
        onSyncCompleted: () => _invalidateSyncedData(ref),
      );
    });

final syncStatusStateProvider = Provider<AsyncValue<SyncStatusState?>>((ref) {
  final userId = ref.watch(
    authControllerProvider.select((state) => state.user?.id),
  );
  if (userId == null) return const AsyncValue.data(null);

  final runtime = ref.watch(syncStatusControllerProvider);
  final summary = ref.watch(syncMetadataSummaryProvider);

  return summary.whenData((value) {
    return SyncStatusController.mergeState(runtime: runtime, summary: value);
  });
});

class SyncStatusController extends StateNotifier<SyncStatusState> {
  SyncStatusController({
    required AutoSyncCoordinator? coordinator,
    required DateTime Function() clock,
    VoidCallback? onSyncCompleted,
  }) : _coordinator = coordinator,
       _clock = clock,
       _onSyncCompleted = onSyncCompleted,
       super(const SyncStatusState.idle());

  final AutoSyncCoordinator? _coordinator;
  final DateTime Function() _clock;
  final VoidCallback? _onSyncCompleted;

  Future<void> syncNow({required String userId}) async {
    if (state.status == SyncUiStatus.syncing) {
      state = state.copyWith(
        lastSyncResult: LastSyncResult(
          status: LastSyncResultStatus.skippedAlreadyRunning,
          finishedAt: _clock(),
          message: 'Ya hay una sincronizacion en curso.',
        ),
      );
      return;
    }

    final coordinator = _coordinator;
    if (coordinator == null) {
      state = state.copyWith(
        status: SyncUiStatus.failed,
        lastSyncResult: LastSyncResult(
          status: LastSyncResultStatus.failed,
          finishedAt: _clock(),
          message: 'La sincronizacion no esta disponible en este entorno.',
        ),
      );
      return;
    }

    state = state.copyWith(status: SyncUiStatus.syncing);
    final result = await coordinator.run(userId: userId);
    final finishedAt = _clock();

    state = switch (result.status) {
      AutoSyncStatus.completed => _completedState(result, finishedAt),
      AutoSyncStatus.failed => state.copyWith(
        status: SyncUiStatus.failed,
        lastSyncResult: LastSyncResult(
          status: LastSyncResultStatus.failed,
          finishedAt: finishedAt,
          message: result.errorMessage,
          uploadSynced: result.upload?.synced ?? 0,
        ),
      ),
      AutoSyncStatus.skippedAlreadyRunning => state.copyWith(
        lastSyncResult: LastSyncResult(
          status: LastSyncResultStatus.skippedAlreadyRunning,
          finishedAt: finishedAt,
          message: 'Ya hay una sincronizacion en curso.',
        ),
      ),
    };
  }

  SyncStatusState _completedState(AutoSyncResult result, DateTime finishedAt) {
    _onSyncCompleted?.call();
    return state.copyWith(
      status: SyncUiStatus.synced,
      lastSyncAt: finishedAt,
      lastSyncResult: LastSyncResult(
        status: LastSyncResultStatus.completed,
        finishedAt: finishedAt,
        uploadSynced: result.upload?.synced ?? 0,
        downloadApplied: result.download?.applied ?? 0,
        downloadConflicts: result.download?.conflicts ?? 0,
      ),
    );
  }

  static SyncStatusState mergeState({
    required SyncStatusState runtime,
    required SyncMetadataSummary summary,
  }) {
    final lastSyncAt = _latest(runtime.lastSyncAt, summary.lastSyncedAt);
    final status = _resolveStatus(
      runtime: runtime,
      summary: summary,
      lastSyncAt: lastSyncAt,
    );

    return SyncStatusState(
      status: status,
      lastSyncAt: lastSyncAt,
      lastSyncResult: runtime.lastSyncResult,
      pendingCount: summary.pendingCount,
      conflictCount: summary.conflictCount,
      failedCount: summary.failedCount,
    );
  }

  static SyncUiStatus _resolveStatus({
    required SyncStatusState runtime,
    required SyncMetadataSummary summary,
    required DateTime? lastSyncAt,
  }) {
    if (runtime.status == SyncUiStatus.syncing) return SyncUiStatus.syncing;
    if (summary.conflictCount > 0) return SyncUiStatus.conflict;
    if ((runtime.lastSyncResult?.isFailure ?? false) ||
        summary.failedCount > 0) {
      return SyncUiStatus.failed;
    }
    if (summary.pendingCount > 0) return SyncUiStatus.pendingChanges;
    if (lastSyncAt != null) return SyncUiStatus.synced;
    return SyncUiStatus.idle;
  }

  static DateTime? _latest(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.isAfter(second) ? first : second;
  }
}

typedef VoidCallback = void Function();

void _invalidateSyncedData(Ref ref) {
  if (ref.exists(booksProvider)) ref.invalidate(booksProvider);
  if (ref.exists(statisticsSummaryProvider)) {
    ref.invalidate(statisticsSummaryProvider);
  }
  if (ref.exists(readingInsightsSummaryProvider)) {
    ref.invalidate(readingInsightsSummaryProvider);
  }
  if (ref.exists(readerProfileControllerProvider)) {
    ref.invalidate(readerProfileControllerProvider);
  }
  ref.invalidate(readingSessionsForRangeProvider);
  ref.invalidate(readingSessionsForDayProvider);
  ref.invalidate(readingSessionsForBookProvider);
}
