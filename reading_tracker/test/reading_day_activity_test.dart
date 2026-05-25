import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/reading_sessions/presentation/models/reading_day_activity.dart';

void main() {
  test('groups sessions by day and sums activity', () {
    final day = DateTime(2026, 5, 21);
    final activities = ReadingDayActivity.fromSessions([
      _session('s1', day, pagesRead: 12, minutes: 20),
      _session('s2', day.add(const Duration(hours: 3)), pagesRead: 8),
    ]);

    final activity = activities[DateTime(2026, 5, 21)];

    expect(activity, isNotNull);
    expect(activity!.sessionsCount, 2);
    expect(activity.pagesRead, 20);
    expect(activity.minutes, 20);
    expect(activity.intensity, ReadingActivityIntensity.low);
  });

  test('calculates intensity thresholds', () {
    expect(
      ReadingDayActivity(
        date: DateTime(2026),
        sessionsCount: 0,
        pagesRead: 0,
        minutes: 0,
      ).intensity,
      ReadingActivityIntensity.none,
    );
    expect(
      ReadingDayActivity(
        date: DateTime(2026),
        sessionsCount: 1,
        pagesRead: 0,
        minutes: 15,
      ).intensity,
      ReadingActivityIntensity.low,
    );
    expect(
      ReadingDayActivity(
        date: DateTime(2026),
        sessionsCount: 1,
        pagesRead: 21,
        minutes: 0,
      ).intensity,
      ReadingActivityIntensity.medium,
    );
    expect(
      ReadingDayActivity(
        date: DateTime(2026),
        sessionsCount: 1,
        pagesRead: 51,
        minutes: 0,
      ).intensity,
      ReadingActivityIntensity.high,
    );
  });
}

ReadingSession _session(
  String id,
  DateTime date, {
  int pagesRead = 0,
  int minutes = 0,
}) {
  return ReadingSession(
    id: id,
    bookId: 'book-1',
    date: date,
    minutes: minutes,
    pagesRead: pagesRead,
    createdAt: date,
  );
}
