import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository_impl.dart';
import '../../domain/app_user.dart';
import '../../domain/auth_repository.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
      return AuthController(ref.watch(authRepositoryProvider));
    });

class AuthControllerState {
  const AuthControllerState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  AuthControllerState copyWith({
    AppUser? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthControllerState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthControllerState> {
  AuthController(this._repository) : super(const AuthControllerState()) {
    _loadCurrentUser();
    _subscription = _repository.watchAuthState().listen((user) {
      state = state.copyWith(
        user: user,
        clearUser: user == null,
        isLoading: false,
        clearError: true,
      );
    });
  }

  final AuthRepository _repository;
  StreamSubscription<AppUser?>? _subscription;

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _repository.getCurrentUser();
      state = state.copyWith(user: user, clearUser: user == null);
    } catch (_) {
      state = const AuthControllerState();
    }
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _runAuthAction(() async {
      final user = await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(user: user, clearUser: user == null);
    });
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _runAuthAction(() async {
      final user = await _repository.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(user: user, clearUser: user == null);
    });
  }

  Future<void> signInWithGoogle() {
    return _runAuthAction(_repository.signInWithGoogle);
  }

  Future<void> signOut() {
    return _runAuthAction(() async {
      await _repository.signOut();
      state = state.copyWith(clearUser: true);
    });
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await action();
      state = state.copyWith(isLoading: false, clearError: true);
    } on AuthUnavailableException {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'El inicio de sesion aun no esta configurado en este entorno.',
      );
    } on AuthException catch (error) {
      debugPrint(
        'Supabase authentication failed '
        '(status: ${error.statusCode}): ${error.message}',
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authErrorMessage(error),
      );
    } catch (error, stackTrace) {
      debugPrint('Unexpected authentication failure: $error\n$stackTrace');
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'No se ha podido completar la autenticacion. Intentalo de nuevo.',
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

String _authErrorMessage(AuthException error) {
  final message = error.message.toLowerCase();

  if (message.contains('invalid login credentials')) {
    return 'El correo o la contrasena no son correctos.';
  }
  if (message.contains('email not confirmed')) {
    return 'Confirma tu correo antes de iniciar sesion.';
  }
  if (message.contains('user already registered') ||
      message.contains('already been registered')) {
    return 'Ya existe una cuenta con este correo.';
  }
  if (message.contains('password') &&
      (message.contains('weak') || message.contains('least'))) {
    return 'La contrasena no cumple los requisitos de seguridad.';
  }
  if (error.statusCode == '429' || message.contains('rate limit')) {
    return 'Demasiados intentos. Espera un momento y vuelve a probar.';
  }

  return 'No se ha podido completar la autenticacion. Intentalo de nuevo.';
}
