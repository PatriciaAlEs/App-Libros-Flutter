import '../../domain/entities/reading_session.dart';

enum ReadingActivityIntensity { none, low, medium, high }

class ReadingDayActivity {
  const ReadingDayActivity({
    required this.date,
    required this.sessionsCount,
    required this.pagesRead,
    required this.minutes,
  });

  final DateTime date;
  final int sessionsCount;
  final int pagesRead;
  final int minutes;

  ReadingActivityIntensity get intensity {
    if (pagesRead <= 0 && minutes <= 0) return ReadingActivityIntensity.none;
    if (pagesRead <= 0 && minutes > 0) return ReadingActivityIntensity.low;
    if (pagesRead <= 20) return ReadingActivityIntensity.low;
    if (pagesRead <= 50) return ReadingActivityIntensity.medium;
    return ReadingActivityIntensity.high;
  }

  static Map<DateTime, ReadingDayActivity> fromSessions(
    List<ReadingSession> sessions,
  ) {
    final grouped = <DateTime, _ReadingDayActivityBuilder>{};
    for (final session in sessions) {
      final date = _dateOnly(session.date);
      grouped
          .putIfAbsent(date, () => _ReadingDayActivityBuilder(date))
          .add(session);
    }
    return {
      for (final entry in grouped.entries) entry.key: entry.value.build(),
    };
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class ReadingActivitySummary {
  const ReadingActivitySummary({
    required this.pagesRead,
    required this.minutes,
    required this.activeDays,
  });

  final int pagesRead;
  final int minutes;
  final int activeDays;

  static ReadingActivitySummary fromActivities(
    Iterable<ReadingDayActivity> activities,
  ) {
    return ReadingActivitySummary(
      pagesRead: activities.fold<int>(
        0,
        (total, activity) => total + activity.pagesRead,
      ),
      minutes: activities.fold<int>(
        0,
        (total, activity) => total + activity.minutes,
      ),
      activeDays: activities
          .where(
            (activity) => activity.intensity != ReadingActivityIntensity.none,
          )
          .length,
    );
  }
}

class _ReadingDayActivityBuilder {
  _ReadingDayActivityBuilder(this.date);

  final DateTime date;
  int sessionsCount = 0;
  int pagesRead = 0;
  int minutes = 0;

  void add(ReadingSession session) {
    sessionsCount += 1;
    pagesRead += session.pagesRead;
    minutes += session.minutes;
  }

  ReadingDayActivity build() {
    return ReadingDayActivity(
      date: date,
      sessionsCount: sessionsCount,
      pagesRead: pagesRead,
      minutes: minutes,
    );
  }
}
