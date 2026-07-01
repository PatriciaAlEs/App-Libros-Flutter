import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/sync_orchestrator.dart';
import 'manual_books_sync_provider.dart';

final syncOrchestratorProvider = Provider<SyncOrchestrator?>((ref) {
  final syncBooks = ref.watch(syncPendingBooksToSupabaseProvider);
  if (syncBooks == null) return null;

  return SyncOrchestrator(syncBooks: syncBooks);
});
