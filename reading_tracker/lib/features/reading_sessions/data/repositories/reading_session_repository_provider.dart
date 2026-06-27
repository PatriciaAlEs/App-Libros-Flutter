import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../sync/data/repositories/local_sync_tracker_provider.dart';
import '../../domain/repositories/reading_session_repository.dart';
import 'reading_session_repository_impl.dart';

final readingSessionRepositoryImplProvider =
    Provider<ReadingSessionRepositoryImpl>(
      (ref) => ReadingSessionRepositoryImpl(
        ref.watch(databaseProvider),
        syncTracker: ref.watch(localSyncTrackerProvider),
      ),
    );

final readingSessionRepositoryProvider = Provider<ReadingSessionRepository>(
  (ref) => ref.watch(readingSessionRepositoryImplProvider),
);
