import 'app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser?> getCurrentUser();

  Stream<AppUser?> watchAuthState();

  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AppUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();

  Future<void> signOut();
}

class AuthUnavailableException implements Exception {
  const AuthUnavailableException();

  @override
  String toString() => 'Supabase Auth is not configured.';
}
