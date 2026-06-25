import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/supabase_client_provider.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._client);

  final SupabaseClient? _client;

  @override
  Future<AppUser?> getCurrentUser() async {
    return _client?.auth.currentUser?.toAppUser();
  }

  @override
  Stream<AppUser?> watchAuthState() {
    final client = _client;
    if (client == null) return const Stream<AppUser?>.empty();

    return client.auth.onAuthStateChange.map(
      (state) => state.session?.user.toAppUser(),
    );
  }

  @override
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return response.user?.toAppUser();
  }

  @override
  Future<AppUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signUp(
      email: email.trim(),
      password: password,
    );
    return response.user?.toAppUser();
  }

  @override
  Future<void> signInWithGoogle() async {
    await _auth.signInWithOAuth(OAuthProvider.google);
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
  }

  GoTrueClient get _auth {
    final client = _client;
    if (client == null) throw const AuthUnavailableException();
    return client.auth;
  }
}

extension on User {
  AppUser toAppUser() {
    final metadata = userMetadata ?? const <String, dynamic>{};
    return AppUser(
      id: id,
      email: email,
      displayName: _metadataString(metadata, const [
        'full_name',
        'name',
        'display_name',
      ]),
      avatarUrl: _metadataString(metadata, const ['avatar_url', 'picture']),
    );
  }
}

String? _metadataString(Map<String, dynamic> metadata, List<String> keys) {
  for (final key in keys) {
    final value = metadata[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}
