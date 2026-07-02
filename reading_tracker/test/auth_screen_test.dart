import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/core/backend/supabase_client_provider.dart';
import 'package:reading_tracker/features/auth/domain/app_user.dart';
import 'package:reading_tracker/features/auth/domain/auth_repository.dart';
import 'package:reading_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:reading_tracker/features/auth/presentation/screens/auth_screen.dart';

void main() {
  testWidgets('shows current auth and sync copy without placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(
      _authHost(repository: FakeAuthRepository(), isSupabaseEnabled: true),
    );

    expect(find.text('Continuar sin login'), findsNothing);
    expect(find.textContaining('proximamente'), findsNothing);
    expect(find.textContaining('modo local'), findsNothing);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(
      find.textContaining(
        'biblioteca, sesiones, perfil lector y objetivo anual',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows unavailable environment message when Supabase is disabled',
    (tester) async {
      await tester.pumpWidget(
        _authHost(repository: FakeAuthRepository(), isSupabaseEnabled: false),
      );

      expect(
        find.text('La autenticacion no esta disponible en este entorno.'),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).first).enabled,
        false,
      );
    },
  );

  testWidgets('email CTA signs in and toggles to sign up', (tester) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(
      _authHost(repository: repository, isSupabaseEnabled: true),
    );

    await tester.enterText(find.byType(TextField).at(0), 'reader@test.dev');
    await tester.enterText(find.byType(TextField).at(1), 'secret-password');
    await tester.tap(find.text('Iniciar sesion'));
    await tester.pump();

    expect(repository.signInCalls, 1);
    expect(repository.signUpCalls, 0);
    expect(repository.lastEmail, 'reader@test.dev');

    await tester.tap(find.text('Crear cuenta con email'));
    await tester.pump();
    await tester.tap(find.text('Crear cuenta'));
    await tester.pump();

    expect(repository.signUpCalls, 1);
  });

  testWidgets('shows auth errors from controller', (tester) async {
    await tester.pumpWidget(
      _authHost(
        repository: FakeAuthRepository(shouldFail: true),
        isSupabaseEnabled: true,
      ),
    );

    await tester.tap(find.text('Iniciar sesion'));
    await tester.pump();

    expect(
      find.text(
        'No se ha podido completar la autenticacion. Intentalo de nuevo.',
      ),
      findsOneWidget,
    );
  });
}

Widget _authHost({
  required FakeAuthRepository repository,
  required bool isSupabaseEnabled,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith((ref) => AuthController(repository)),
      isSupabaseEnabledProvider.overrideWith((ref) => isSupabaseEnabled),
    ],
    child: const MaterialApp(home: AuthScreen()),
  );
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.shouldFail = false});

  final bool shouldFail;
  final _controller = StreamController<AppUser?>.broadcast();
  int signInCalls = 0;
  int signUpCalls = 0;
  String? lastEmail;

  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  Stream<AppUser?> watchAuthState() => _controller.stream;

  @override
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (shouldFail) throw StateError('auth failed');
    signInCalls++;
    lastEmail = email;
    return const AppUser(id: 'user-1', email: 'reader@test.dev');
  }

  @override
  Future<AppUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (shouldFail) throw StateError('auth failed');
    signUpCalls++;
    lastEmail = email;
    return const AppUser(id: 'user-1', email: 'reader@test.dev');
  }

  @override
  Future<void> signInWithGoogle() async {
    if (shouldFail) throw StateError('auth failed');
  }

  @override
  Future<void> signOut() async {}
}
