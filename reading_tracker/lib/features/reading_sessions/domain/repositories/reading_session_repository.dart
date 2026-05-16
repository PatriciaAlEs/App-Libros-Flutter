import '../entities/reading_session.dart';

abstract interface class ReadingSessionRepository {
  Future<void> addSession(ReadingSession session);
  Future<void> updateSession(ReadingSession session);
  Future<void> deleteSession(String id);
  Future<List<ReadingSession>> getSessionsForDay(DateTime day);
  Future<List<ReadingSession>> getSessionsInRange(DateTime start, DateTime end);
  Stream<List<ReadingSession>> watchSessionsInRange(
    DateTime start,
    DateTime end,
  );
}
