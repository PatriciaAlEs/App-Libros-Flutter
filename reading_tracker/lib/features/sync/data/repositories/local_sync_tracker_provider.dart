import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/local_sync_tracker.dart';
import 'sync_metadata_repository_provider.dart';

final localSyncTrackerProvider = Provider<LocalSyncTracker>((ref) {
  return LocalSyncTracker(ref.watch(syncMetadataRepositoryProvider));
});
