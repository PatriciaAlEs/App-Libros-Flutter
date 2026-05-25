import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_tracker/features/books/data/repositories/book_repository_provider.dart';
import 'package:reading_tracker/features/insights/domain/repositories/insights_repository.dart';
import 'package:reading_tracker/features/reading_sessions/data/repositories/reading_session_repository_provider.dart';

import 'insights_repository_impl.dart';

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return InsightsRepositoryImpl(
    bookRepository: ref.watch(bookRepositoryProvider),
    readingSessionRepository: ref.watch(readingSessionRepositoryProvider),
  );
});
