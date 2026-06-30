import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/remote_books_repository.dart';
import '../datasources/supabase_remote_sync_datasource.dart';
import 'supabase_remote_books_repository.dart';

final remoteBooksRepositoryProvider = Provider<RemoteBooksRepository?>((ref) {
  final datasource = ref.watch(remoteSyncDatasourceProvider);
  if (datasource == null) return null;
  return SupabaseRemoteBooksRepository(datasource);
});
