import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_tracker/core/database/database_provider.dart';
import 'package:reading_tracker/features/books/data/repositories/book_repository_provider.dart';
import 'package:reading_tracker/features/reading_sessions/data/mappers/reading_session_mapper.dart';
import 'package:reading_tracker/features/stats/domain/stats_calculator.dart';

final statsProvider = FutureProvider<StatsData>((ref) async {
  final books = await ref.read(bookRepositoryProvider).getAllBooks();
  final sessionDao = ref.read(readingSessionDaoProvider);
  final sessionsData = await sessionDao.getSessionsInRange(
    DateTime.fromMillisecondsSinceEpoch(0),
    DateTime.now(),
  );
  final sessions = sessionsData.map((row) => row.toDomain()).toList();

  return calculateStats(books, sessions);
});
