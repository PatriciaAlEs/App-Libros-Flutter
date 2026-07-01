import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/auto_sync_coordinator.dart';
import 'sync_orchestrator_provider.dart';

final autoSyncCoordinatorProvider = Provider<AutoSyncCoordinator?>((ref) {
  final orchestrator = ref.watch(syncOrchestratorProvider);
  if (orchestrator == null) return null;

  return AutoSyncCoordinator(orchestrator: orchestrator);
});
