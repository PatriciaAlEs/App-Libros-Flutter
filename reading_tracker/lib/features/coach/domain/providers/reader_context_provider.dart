import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/preferences/reader_profile_controller.dart';
import '../../../books/data/repositories/book_repository_provider.dart';
import '../../../reading_sessions/data/repositories/reading_session_repository_provider.dart';
import '../../../stats/data/repositories/annual_reading_goal_repository_provider.dart';
import '../models/reader_context.dart';
import '../services/reader_context_builder.dart';
import '../services/reader_context_builder_impl.dart';

final readerContextBuilderProvider = Provider<ReaderContextBuilder>((ref) {
  final readerProfile = ref.watch(readerProfileControllerProvider);

  return ReaderContextBuilderImpl(
    bookRepository: ref.watch(bookRepositoryProvider),
    readingSessionRepository: ref.watch(readingSessionRepositoryProvider),
    annualReadingGoalRepository: ref.watch(annualReadingGoalRepositoryProvider),
    readerProfileLoader: () async => readerProfile,
  );
});

final readerContextProvider = FutureProvider<ReaderContext>((ref) {
  final builder = ref.watch(readerContextBuilderProvider);
  return builder.build();
});
