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
  test('logout restaura estado anonimo de forma reactiva', () async {
    final repository = FakeAuthRepository();
    final controller = AuthController(repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    repository.emit(const AppUser(id: 'signed-user', email: 'reader@test.dev'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.isAuthenticated, isTrue);

    await controller.signOut();

    expect(controller.state.isAuthenticated, isFalse);
    expect(controller.state.isLoading, isFalse);
  });

  test('diferencia callback incompleto de cancelacion OAuth', () async {
    final incomplete = AuthController(
      FakeAuthRepository(),
      launchUri: Uri.parse('https://readpp.dev/?code=incomplete'),
    );
    addTearDown(incomplete.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(incomplete.state.errorMessage, contains('retorno de Google'));

    final cancelled = AuthController(
      FakeAuthRepository(),
      launchUri: Uri.parse('https://readpp.dev/?error=access_denied'),
    );
    addTearDown(cancelled.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(cancelled.state.errorMessage, isNull);
    expect(cancelled.state.isRestoring, isFalse);
  });

  test('evento autenticado gana a restauracion anonima obsoleta', () async {
    final repository = ControlledAuthRepository();
    final controller = AuthController(repository);
    addTearDown(controller.dispose);

    const user = AppUser(id: 'google-user', email: 'google@test.dev');
    repository.emit(user);
    repository.completeCurrentUser(null);
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.user, user);

    repository.emit(null);
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.user, user);
    expect(controller.state.isLoading, isFalse);
  });

  testWidgets('shows current auth and sync copy without placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(
      _authHost(repository: FakeAuthRepository(), isSupabaseEnabled: true),
    );
    await tester.pump();

    expect(find.text('Continuar sin login'), findsNothing);
    expect(find.textContaining('proximamente'), findsNothing);
    expect(find.textContaining('modo local'), findsNothing);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('Entrar con correo'), findsOneWidget);
    expect(find.text('Bienvenida a ReadPp'), findsOneWidget);
    expect(
      find.textContaining('Tu compañero de lecturas inteligente.'),
      findsOneWidget,
    );
    expect(find.textContaining('Terminos de uso'), findsOneWidget);
  });

  testWidgets(
    'shows unavailable environment message when Supabase is disabled',
    (tester) async {
      await tester.pumpWidget(
        _authHost(repository: FakeAuthRepository(), isSupabaseEnabled: false),
      );
      await tester.pump();

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
    final signInRepository = FakeAuthRepository();
    await tester.pumpWidget(
      _authHost(repository: signInRepository, isSupabaseEnabled: true),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'reader@test.dev');
    await tester.enterText(find.byType(TextField).at(1), 'secret-password');
    await tester.tap(find.text('Entrar con correo'));
    await tester.pump();

    expect(signInRepository.signInCalls, 1);
    expect(signInRepository.signUpCalls, 0);
    expect(signInRepository.lastEmail, 'reader@test.dev');

    await tester.pumpWidget(const SizedBox.shrink());
    final signUpRepository = FakeAuthRepository();
    await tester.pumpWidget(
      _authHost(repository: signUpRepository, isSupabaseEnabled: true),
    );
    await tester.pump();

    await tester.tap(find.text('¿Aun no tienes cuenta? Registrate'));
    await tester.pump();
    expect(find.text('¿Ya tienes una cuenta? Inicia sesion'), findsOneWidget);
    await tester.tap(find.text('Crear una cuenta'));
    await tester.pump();

    expect(signUpRepository.signUpCalls, 1);
  });

  testWidgets('shows auth errors from controller', (tester) async {
    await tester.pumpWidget(
      _authHost(
        repository: FakeAuthRepository(shouldFail: true),
        isSupabaseEnabled: true,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Entrar con correo'));
    await tester.pump();

    expect(
      find.text(
        'No se ha podido completar la autenticacion. Intentalo de nuevo.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('mantiene loading durante restauracion de sesion', (
    tester,
  ) async {
    final repository = ControlledAuthRepository();
    await tester.pumpWidget(
      _authHost(repository: repository, isSupabaseEnabled: true),
    );

    expect(find.text('Comprobando tu sesion…'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).first).enabled,
      false,
    );

    repository.emit(null);
    repository.completeCurrentUser(null);
    await tester.pump();

    expect(find.text('Comprobando tu sesion…'), findsNothing);
  });

  testWidgets('Google es una accion unica y bloquea doble submit', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(
      _authHost(repository: repository, isSupabaseEnabled: true),
    );
    await tester.pump();

    await tester.tap(find.text('Continuar con Google'));
    await tester.pump();
    await tester.tap(find.text('Continuar con Google'));

    expect(repository.googleCalls, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).first).enabled,
      false,
    );
  });

  testWidgets('login y registro comparten la identidad visual ReadPp', (
    tester,
  ) async {
    await tester.pumpWidget(
      _authHost(repository: FakeAuthRepository(), isSupabaseEnabled: true),
    );
    await tester.pump();

    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    expect(find.text('INICIAR SESION'), findsOneWidget);
    expect(find.text('Entrar con correo'), findsOneWidget);

    await tester.tap(find.textContaining('Registrate'));
    await tester.pump();

    expect(find.text('CREAR CUENTA'), findsOneWidget);
    expect(find.text('Registrarse con Google'), findsOneWidget);
    expect(find.text('Crear una cuenta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('primer evento autenticado navega sin segunda accion', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController(repository),
          ),
          isSupabaseEnabledProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
          initialRoute: '/auth',
          routes: {
            '/': (_) => const Scaffold(key: Key('authenticated-home')),
            '/auth': (_) => const AuthScreen(),
          },
        ),
      ),
    );
    await tester.pump();

    repository.emit(const AppUser(id: 'google-user', email: 'google@test.dev'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('authenticated-home')), findsOneWidget);
    expect(repository.googleCalls, 0);
  });
}

Widget _authHost({
  required AuthRepository repository,
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
  int googleCalls = 0;
  String? lastEmail;

  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  Stream<AppUser?> watchAuthState() async* {
    yield null;
    yield* _controller.stream;
  }

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
  Future<bool> signInWithGoogle() async {
    if (shouldFail) throw StateError('auth failed');
    googleCalls++;
    return true;
  }

  @override
  Future<void> signOut() async {}

  void emit(AppUser? user) => _controller.add(user);
}

class ControlledAuthRepository implements AuthRepository {
  final _currentUser = Completer<AppUser?>();
  final _authState = StreamController<AppUser?>.broadcast();

  void completeCurrentUser(AppUser? user) => _currentUser.complete(user);
  void emit(AppUser? user) => _authState.add(user);

  @override
  Future<AppUser?> getCurrentUser() => _currentUser.future;

  @override
  Stream<AppUser?> watchAuthState() => _authState.stream;

  @override
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<AppUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<void> signOut() async {}
}
