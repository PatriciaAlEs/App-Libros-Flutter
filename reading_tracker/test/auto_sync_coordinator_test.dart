import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/auth/domain/app_user.dart';
import 'package:reading_tracker/features/auth/domain/auth_repository.dart';
import 'package:reading_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:reading_tracker/features/sync/data/repositories/auto_sync_coordinator_provider.dart';
import 'package:reading_tracker/features/sync/data/repositories/sync_orchestrator_provider.dart';
import 'package:reading_tracker/features/sync/domain/services/auto_sync_coordinator.dart';
import 'package:reading_tracker/features/sync/domain/services/sync_orchestrator.dart';
import 'package:reading_tracker/features/sync/domain/usecases/download_annual_goal_from_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/download_books_from_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/download_reader_profile_from_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/download_reading_sessions_from_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_annual_goal_to_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_books_to_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_reader_profile_to_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_reading_sessions_to_supabase.dart';
import 'package:reading_tracker/features/sync/presentation/widgets/auto_sync_bootstrap.dart';

void main() {
  test('executes upload before download with the provided user id', () async {
    final operations = <String>[];
    final userIds = <String>[];
    final coordinator = AutoSyncCoordinator.withRunners(
      runUpload: ({required userId}) async {
        operations.add('upload');
        userIds.add(userId);
        return _uploadResult();
      },
      runDownload: ({required userId}) async {
        operations.add('download');
        userIds.add(userId);
        return _downloadResult();
      },
    );

    final result = await coordinator.run(userId: 'user-1');

    expect(result.status, AutoSyncStatus.completed);
    expect(operations, ['upload', 'download']);
    expect(userIds, ['user-1', 'user-1']);
  });

  test('does not execute download when upload fails completely', () async {
    final operations = <String>[];
    final coordinator = AutoSyncCoordinator.withRunners(
      runUpload: ({required userId}) async {
        operations.add('upload');
        throw StateError('upload failed');
      },
      runDownload: ({required userId}) async {
        operations.add('download');
        return _downloadResult();
      },
    );

    final result = await coordinator.run(userId: 'user-1');

    expect(result.status, AutoSyncStatus.failed);
    expect(result.errorMessage, contains('upload failed'));
    expect(result.upload, isNull);
    expect(result.download, isNull);
    expect(operations, ['upload']);
  });

  test('captures download errors without throwing', () async {
    final coordinator = AutoSyncCoordinator.withRunners(
      runUpload: ({required userId}) async => _uploadResult(),
      runDownload: ({required userId}) async {
        throw StateError('download failed');
      },
    );

    final result = await coordinator.run(userId: 'user-1');

    expect(result.status, AutoSyncStatus.failed);
    expect(result.upload, isNotNull);
    expect(result.download, isNull);
    expect(result.errorMessage, contains('download failed'));
  });

  test('cleans the lock after success and after failure', () async {
    var uploads = 0;
    final coordinator = AutoSyncCoordinator.withRunners(
      runUpload: ({required userId}) async {
        uploads++;
        if (uploads == 2) throw StateError('second upload failed');
        return _uploadResult();
      },
      runDownload: ({required userId}) async => _downloadResult(),
    );

    final first = await coordinator.run(userId: 'user-1');
    final second = await coordinator.run(userId: 'user-1');
    final third = await coordinator.run(userId: 'user-1');

    expect(first.status, AutoSyncStatus.completed);
    expect(second.status, AutoSyncStatus.failed);
    expect(third.status, AutoSyncStatus.completed);
    expect(coordinator.isRunning, isFalse);
    expect(uploads, 3);
  });

  test(
    'returns skippedAlreadyRunning when a sync is already in progress',
    () async {
      final uploadCompleter = Completer<SyncOrchestrationResult>();
      final coordinator = AutoSyncCoordinator.withRunners(
        runUpload: ({required userId}) => uploadCompleter.future,
        runDownload: ({required userId}) async => _downloadResult(),
      );

      final running = coordinator.run(userId: 'user-1');
      await Future<void>.delayed(Duration.zero);

      final skipped = await coordinator.run(userId: 'user-1');
      uploadCompleter.complete(_uploadResult());
      final completed = await running;

      expect(skipped.status, AutoSyncStatus.skippedAlreadyRunning);
      expect(completed.status, AutoSyncStatus.completed);
      expect(coordinator.isRunning, isFalse);
    },
  );

  test('provider returns null when there is no SyncOrchestrator', () {
    final container = ProviderContainer(
      overrides: [syncOrchestratorProvider.overrideWith((ref) => null)],
    );
    addTearDown(container.dispose);

    expect(container.read(autoSyncCoordinatorProvider), isNull);
  });

  testWidgets('bootstrap triggers sync with an authenticated user', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository(
      initialUser: const AppUser(id: 'user-1'),
    );
    final syncCalls = <String>[];
    final coordinator = _recordingCoordinator(syncCalls);

    await tester.pumpWidget(
      _bootstrapHost(authRepository: authRepository, coordinator: coordinator),
    );
    await tester.pump();

    expect(syncCalls, ['user-1']);
  });

  testWidgets('bootstrap does not trigger sync without an authenticated user', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();
    final syncCalls = <String>[];
    final coordinator = _recordingCoordinator(syncCalls);

    await tester.pumpWidget(
      _bootstrapHost(authRepository: authRepository, coordinator: coordinator),
    );
    await tester.pump();

    expect(syncCalls, isEmpty);
  });

  testWidgets('bootstrap triggers sync when login provides a user', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();
    final syncCalls = <String>[];
    final coordinator = _recordingCoordinator(syncCalls);

    await tester.pumpWidget(
      _bootstrapHost(authRepository: authRepository, coordinator: coordinator),
    );
    await tester.pump();

    authRepository.emit(const AppUser(id: 'user-1'));
    await tester.pump();
    await tester.pump();

    expect(syncCalls, ['user-1']);
  });

  testWidgets('bootstrap does not repeat sync on a simple rebuild', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository(
      initialUser: const AppUser(id: 'user-1'),
    );
    final syncCalls = <String>[];
    final coordinator = _recordingCoordinator(syncCalls);

    await tester.pumpWidget(
      _bootstrapHost(authRepository: authRepository, coordinator: coordinator),
    );
    await tester.pump();
    await tester.pumpWidget(
      _bootstrapHost(authRepository: authRepository, coordinator: coordinator),
    );
    await tester.pump();

    expect(syncCalls, ['user-1']);
  });
}

Widget _bootstrapHost({
  required FakeAuthRepository authRepository,
  required AutoSyncCoordinator coordinator,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => AuthController(authRepository),
      ),
      autoSyncCoordinatorProvider.overrideWith((ref) => coordinator),
    ],
    child: const Directionality(
      textDirection: TextDirection.ltr,
      child: AutoSyncBootstrap(child: SizedBox.shrink()),
    ),
  );
}

AutoSyncCoordinator _recordingCoordinator(List<String> syncCalls) {
  return AutoSyncCoordinator.withRunners(
    runUpload: ({required userId}) async {
      syncCalls.add(userId);
      return _uploadResult();
    },
    runDownload: ({required userId}) async => _downloadResult(),
  );
}

SyncOrchestrationResult _uploadResult() {
  return const SyncOrchestrationResult(
    books: SyncPendingBooksResult(
      pendingBooks: 1,
      synced: 1,
      failed: 0,
      ignored: 0,
    ),
    readingSessions: SyncPendingReadingSessionsResult(
      pendingReadingSessions: 0,
      synced: 0,
      failed: 0,
      ignored: 0,
    ),
    readerProfile: SyncPendingReaderProfileResult(
      pendingReaderProfiles: 0,
      synced: 0,
      failed: 0,
      ignored: 0,
    ),
    annualGoal: SyncPendingAnnualGoalResult(
      pendingAnnualGoals: 0,
      synced: 0,
      failed: 0,
      ignored: 0,
    ),
  );
}

SyncDownloadOrchestrationResult _downloadResult() {
  return const SyncDownloadOrchestrationResult(
    books: DownloadBooksResult(
      remoteBooks: 1,
      applied: 1,
      skipped: 0,
      conflicts: 0,
      failed: 0,
    ),
    readingSessions: DownloadReadingSessionsResult(
      remoteReadingSessions: 0,
      applied: 0,
      skipped: 0,
      conflicts: 0,
      failed: 0,
    ),
    readerProfile: DownloadReaderProfileResult(
      remoteProfiles: 0,
      applied: 0,
      skipped: 0,
      conflicts: 0,
      failed: 0,
    ),
    annualGoal: DownloadAnnualGoalResult(
      remoteAnnualGoals: 0,
      applied: 0,
      skipped: 0,
      conflicts: 0,
      failed: 0,
    ),
  );
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.initialUser});

  final AppUser? initialUser;
  final _controller = StreamController<AppUser?>.broadcast();

  void emit(AppUser? user) {
    _controller.add(user);
  }

  @override
  Future<AppUser?> getCurrentUser() async => initialUser;

  @override
  Stream<AppUser?> watchAuthState() => _controller.stream;

  @override
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return initialUser;
  }

  @override
  Future<AppUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return initialUser;
  }

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}
