import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/auth/domain/app_user.dart';
import 'package:reading_tracker/features/auth/domain/auth_repository.dart';
import 'package:reading_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:reading_tracker/features/sync/domain/entities/sync_status_state.dart';
import 'package:reading_tracker/features/sync/presentation/controllers/sync_status_controller.dart';
import 'package:reading_tracker/features/sync/presentation/widgets/auto_sync_bootstrap.dart';
import 'package:reading_tracker/features/sync/presentation/widgets/sync_status_card.dart';

void main() {
  testWidgets('sync status card shows synced state', (tester) async {
    await tester.pumpWidget(
      _cardHost(
        authRepository: FakeAuthRepository(
          initialUser: const AppUser(id: 'user-1'),
        ),
        state: SyncStatusState(
          status: SyncUiStatus.synced,
          lastSyncAt: DateTime(2026, 7, 1, 9, 30),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('sync_status_card')), findsOneWidget);
    expect(find.text('Todo sincronizado'), findsOneWidget);
    expect(find.textContaining('Ultima sync: 01/07 09:30'), findsOneWidget);
  });

  testWidgets('sync status card shows pending changes', (tester) async {
    await tester.pumpWidget(
      _cardHost(
        authRepository: FakeAuthRepository(
          initialUser: const AppUser(id: 'user-1'),
        ),
        state: const SyncStatusState(
          status: SyncUiStatus.pendingChanges,
          pendingCount: 3,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Cambios pendientes'), findsOneWidget);
    expect(find.textContaining('Pendientes: 3'), findsOneWidget);
  });

  testWidgets('sync status card shows conflict state', (tester) async {
    await tester.pumpWidget(
      _cardHost(
        authRepository: FakeAuthRepository(
          initialUser: const AppUser(id: 'user-1'),
        ),
        state: const SyncStatusState(
          status: SyncUiStatus.conflict,
          pendingCount: 1,
          conflictCount: 1,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Conflictos detectados'), findsOneWidget);
    expect(find.textContaining('Conflictos: 1'), findsOneWidget);
  });

  testWidgets('sync status card shows failed state', (tester) async {
    await tester.pumpWidget(
      _cardHost(
        authRepository: FakeAuthRepository(
          initialUser: const AppUser(id: 'user-1'),
        ),
        state: SyncStatusState(
          status: SyncUiStatus.failed,
          lastSyncResult: LastSyncResult(
            status: LastSyncResultStatus.failed,
            finishedAt: DateTime(2026, 7),
            message: 'Supabase is unavailable',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sincronizacion fallida'), findsOneWidget);
    expect(find.text('Supabase is unavailable'), findsOneWidget);
  });

  testWidgets('sync status card shows syncing state', (tester) async {
    await tester.pumpWidget(
      _cardHost(
        authRepository: FakeAuthRepository(
          initialUser: const AppUser(id: 'user-1'),
        ),
        state: const SyncStatusState(status: SyncUiStatus.syncing),
      ),
    );
    await tester.pump();

    expect(find.text('Sincronizando'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).enabled,
      false,
    );
  });

  testWidgets('sync status card is hidden without an authenticated user', (
    tester,
  ) async {
    await tester.pumpWidget(
      _cardHost(
        authRepository: FakeAuthRepository(),
        state: const SyncStatusState(status: SyncUiStatus.synced),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('sync_status_card')), findsNothing);
    expect(find.text('Sincronizar ahora'), findsNothing);
  });

  testWidgets('sync now button calls SyncStatusController.syncNow', (
    tester,
  ) async {
    final controller = RecordingSyncStatusController();
    await tester.pumpWidget(
      _cardHost(
        authRepository: FakeAuthRepository(
          initialUser: const AppUser(id: 'user-1'),
        ),
        state: const SyncStatusState(status: SyncUiStatus.idle),
        controller: controller,
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('sync_now_button')));
    await tester.pump();

    expect(controller.syncCalls, ['user-1']);
  });

  testWidgets(
    'bootstrap calls SyncStatusController and avoids rebuild repeats',
    (tester) async {
      final authRepository = FakeAuthRepository(
        initialUser: const AppUser(id: 'user-1'),
      );
      final controller = RecordingSyncStatusController();

      await tester.pumpWidget(
        _bootstrapHost(authRepository: authRepository, controller: controller),
      );
      await tester.pump();
      await tester.pumpWidget(
        _bootstrapHost(authRepository: authRepository, controller: controller),
      );
      await tester.pump();

      expect(controller.syncCalls, ['user-1']);
    },
  );
}

Widget _cardHost({
  required FakeAuthRepository authRepository,
  required SyncStatusState state,
  RecordingSyncStatusController? controller,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => AuthController(authRepository),
      ),
      syncStatusStateProvider.overrideWith((ref) => AsyncValue.data(state)),
      syncStatusControllerProvider.overrideWith(
        (ref) => controller ?? RecordingSyncStatusController(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: SyncStatusCard())),
  );
}

Widget _bootstrapHost({
  required FakeAuthRepository authRepository,
  required RecordingSyncStatusController controller,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => AuthController(authRepository),
      ),
      syncStatusControllerProvider.overrideWith((ref) => controller),
    ],
    child: const Directionality(
      textDirection: TextDirection.ltr,
      child: AutoSyncBootstrap(child: SizedBox.shrink()),
    ),
  );
}

class RecordingSyncStatusController extends SyncStatusController {
  RecordingSyncStatusController()
    : super(coordinator: null, clock: () => DateTime(2026, 7));

  final List<String> syncCalls = [];

  @override
  Future<void> syncNow({required String userId}) async {
    syncCalls.add(userId);
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.initialUser});

  final AppUser? initialUser;
  final _controller = StreamController<AppUser?>.broadcast();

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
