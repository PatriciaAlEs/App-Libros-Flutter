import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../books/domain/entities/book.dart';
import '../../../books/presentation/providers/books_provider.dart';
import '../../data/repositories/reading_session_repository_provider.dart';
import '../../domain/entities/reading_session.dart';

class DateRange {
  const DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) {
    return other is DateRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

final readingSessionsForRangeProvider =
    StreamProvider.family<List<ReadingSession>, DateRange>((ref, range) {
      final repository = ref.watch(readingSessionRepositoryProvider);
      return repository.watchSessionsInRange(range.start, range.end);
    });

final readingSessionsForDayProvider =
    FutureProvider.family<List<ReadingSession>, DateTime>((ref, day) {
      final repository = ref.watch(readingSessionRepositoryProvider);
      return repository.getSessionsForDay(day);
    });

final sessionsTotalMinutesProvider = Provider.family<int, List<ReadingSession>>(
  (ref, sessions) {
    return sessions.fold<int>(0, (total, session) => total + session.minutes);
  },
);

final booksByIdProvider = Provider<Map<String, Book>>((ref) {
  final booksAsync = ref.watch(booksProvider);
  return booksAsync.maybeWhen(
    data: (books) => {for (final book in books) book.id: book},
    orElse: () => const {},
  );
});
