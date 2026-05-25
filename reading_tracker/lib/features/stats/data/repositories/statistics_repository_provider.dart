import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_tracker/features/books/data/repositories/book_repository_provider.dart';
import 'package:reading_tracker/features/reading_sessions/data/repositories/reading_session_repository_provider.dart';
import 'package:reading_tracker/features/stats/domain/repositories/statistics_repository.dart';

import 'annual_reading_goal_repository_provider.dart';
import 'book_statistics_repository.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return BookStatisticsRepository(
    bookRepository: ref.watch(bookRepositoryProvider),
    readingSessionRepository: ref.watch(readingSessionRepositoryProvider),
    annualReadingGoalRepository: ref.watch(annualReadingGoalRepositoryProvider),
  );
});
