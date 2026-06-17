import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../books/presentation/providers/books_provider.dart';
import '../../../insights/presentation/providers/reading_insights_summary_provider.dart';
import '../../../stats/presentation/providers/statistics_summary_provider.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import '../providers/reading_sessions_provider.dart';

void refreshReadingSessionUi(
  WidgetRef ref, {
  Iterable<DateTime> days = const [],
}) {
  for (final day in days) {
    ref.invalidate(readingSessionsForDayProvider(_dateOnly(day)));
  }
  ref.invalidate(readingSessionsForDayProvider);
  ref.invalidate(readingSessionsForRangeProvider);
  ref.invalidate(readingSessionsForBookProvider);
  ref.invalidate(statsProvider);
  ref.invalidate(statisticsSummaryProvider);
  ref.invalidate(readingInsightsSummaryProvider);
  ref.invalidate(booksProvider);
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
