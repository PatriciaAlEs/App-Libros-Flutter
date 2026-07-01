import '../../domain/entities/remote_reading_session.dart';
import '../../domain/repositories/remote_reading_sessions_repository.dart';
import '../datasources/remote_sync_datasource.dart';
import '../datasources/remote_sync_tables.dart';
import '../mappers/remote_reading_session_mapper.dart';
import '../models/remote_reading_session_dto.dart';

class SupabaseRemoteReadingSessionsRepository
    implements RemoteReadingSessionsRepository {
  const SupabaseRemoteReadingSessionsRepository(this._datasource);

  final RemoteSyncDatasource _datasource;

  @override
  Future<List<RemoteReadingSession>> getReadingSessions({
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  }) async {
    final rows = await _datasource.selectMany(
      table: RemoteSyncTables.readingSessions,
      userId: userId,
      updatedAfter: updatedAfter,
      includeDeleted: includeDeleted,
    );

    return rows
        .map((row) => RemoteReadingSessionDto.fromJson(row).toDomain())
        .toList();
  }

  @override
  Future<List<RemoteReadingSession>> upsertReadingSessions(
    List<RemoteReadingSession> sessions,
  ) async {
    final rows = await _datasource.upsertMany(
      table: RemoteSyncTables.readingSessions,
      rows: sessions.map((session) => session.toDto().toJson()).toList(),
      // user_id + local_session_id has a partial unique index in Supabase.
      onConflict: RemoteSyncColumns.id,
    );

    return rows
        .map((row) => RemoteReadingSessionDto.fromJson(row).toDomain())
        .toList();
  }

  @override
  Future<void> deleteReadingSession({
    required String userId,
    required String remoteSessionId,
  }) {
    return _datasource.deleteOne(
      table: RemoteSyncTables.readingSessions,
      userId: userId,
      id: remoteSessionId,
    );
  }
}
