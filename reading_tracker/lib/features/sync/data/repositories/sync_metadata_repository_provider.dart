import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../domain/repositories/sync_metadata_repository.dart';
import 'local_sync_metadata_repository.dart';

final syncMetadataRepositoryProvider = Provider<SyncMetadataRepository>((ref) {
  return LocalSyncMetadataRepository(
    ref.watch(databaseProvider).syncMetadataDao,
  );
});
