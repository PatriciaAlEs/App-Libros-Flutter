import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository_impl.dart';
import '../../data/auth_redirect_url.dart';
import '../../domain/app_user.dart';
import '../../domain/auth_repository.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
      return AuthController(ref.watch(authRepositoryProvider));
    });

class AuthControllerState {
  const AuthControllerState({
    this.user,
    this.isRestoring = true,
    this.isLoading = false,
    this.errorMessage,
  });

  final AppUser? user;
  final bool isRestoring;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  AuthControllerState copyWith({
    AppUser? user,
    bool? isRestoring,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthControllerState(
      user: clearUser ? null : user ?? this.user,
      isRestoring: isRestoring ?? this.isRestoring,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthControllerState> {
  AuthController(this._repository, {Uri? launchUri})
    : _launchUri = launchUri ?? Uri.base,
      super(const AuthControllerState()) {
    _subscription = _repository.watchAuthState().listen(
      (user) {
        _latestAuthEvent = user;
        if (!_firstAuthEvent.isCompleted) _firstAuthEvent.complete();
        if (!state.isRestoring) _applyAuthenticatedUser(user);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_firstAuthEvent.isCompleted) {
          _firstAuthEvent.completeError(error, stackTrace);
          return;
        }
        debugPrint('Authentication state stream failed: $error\n$stackTrace');
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Se ha perdido la conexion con la sesion. Intentalo de nuevo.',
        );
      },
    );
    _restoreSession();
  }

  final AuthRepository _repository;
  final Uri _launchUri;
  StreamSubscription<AppUser?>? _subscription;
  final Completer<void> _firstAuthEvent = Completer<void>();
  AppUser? _latestAuthEvent;

  Future<void> _restoreSession() async {
    try {
      final currentUserFuture = _repository.getCurrentUser();
      await _firstAuthEvent.future;
      final currentUser = await currentUserFuture;
      final user = _latestAuthEvent ?? currentUser;
      if (user == null && isOAuthCallbackUri(_launchUri)) {
        state = AuthControllerState(
          isRestoring: false,
          errorMessage: isOAuthCancellationUri(_launchUri)
              ? null
              : 'No se ha podido completar el retorno de Google. Intentalo de nuevo.',
        );
      } else {
        _applyAuthenticatedUser(user);
      }
    } catch (error, stackTrace) {
      debugPrint('Authentication session restoration failed: $error\n$stackTrace');
      state = const AuthControllerState(
        isRestoring: false,
        errorMessage:
            'No se ha podido restaurar la sesion. Puedes seguir en modo local.',
      );
    }
  }

  void _applyAuthenticatedUser(AppUser? user) {
    state = state.copyWith(
      user: user,
      clearUser: user == null,
      isRestoring: false,
      isLoading: false,
      clearError: true,
    );
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
    return _runGoogleAuth();
  }

  Future<void> _runGoogleAuth() async {
    if (state.isLoading || state.isRestoring) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final redirectStarted = await _repository.signInWithGoogle();
      if (!redirectStarted) {
        state = state.copyWith(isLoading: false, clearError: true);
      }
      // A successful OAuth launch stays loading until onAuthStateChange
      // confirms a session (or the redirect rebuilds the application).
    } on AuthUnavailableException {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'El inicio de sesion aun no esta configurado en este entorno.',
      );
    } on AuthException catch (error) {
      debugPrint(
        'Supabase Google authentication failed '
        '(status: ${error.statusCode}): ${error.message}',
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authErrorMessage(error),
      );
    } catch (error, stackTrace) {
      debugPrint('Unexpected Google authentication failure: $error\n$stackTrace');
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'No se ha podido conectar con Google. Revisa tu conexion e intentalo de nuevo.',
      );
    }
  }

  Future<void> signOut() {
    return _runAuthAction(() async {
      await _repository.signOut();
      state = state.copyWith(clearUser: true);
    });
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    if (state.isLoading || state.isRestoring) return;
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
  if (message.contains('network') ||
      message.contains('socket') ||
      message.contains('failed to fetch')) {
    return 'No se ha podido conectar. Revisa tu conexion e intentalo de nuevo.';
  }

  return 'No se ha podido completar la autenticacion. Intentalo de nuevo.';
}
