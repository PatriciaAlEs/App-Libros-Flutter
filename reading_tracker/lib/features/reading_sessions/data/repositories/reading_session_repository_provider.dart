import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../domain/repositories/reading_session_repository.dart';
import 'reading_session_repository_impl.dart';

final readingSessionRepositoryImplProvider =
    Provider<ReadingSessionRepositoryImpl>(
      (ref) => ReadingSessionRepositoryImpl(ref.watch(databaseProvider)),
    );

final readingSessionRepositoryProvider = Provider<ReadingSessionRepository>(
  (ref) => ref.watch(readingSessionRepositoryImplProvider),
);
