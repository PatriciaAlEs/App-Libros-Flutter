import '../entities/remote_reading_session.dart';

abstract interface class RemoteReadingSessionsRepository {
  Future<List<RemoteReadingSession>> getReadingSessions({
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  });

  Future<void> upsertReadingSessions(List<RemoteReadingSession> sessions);
  Future<void> deleteReadingSession({
    required String userId,
    required String remoteSessionId,
  });
}
