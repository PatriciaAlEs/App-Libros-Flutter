import 'package:uuid/uuid.dart';

import '../../../reading_sessions/domain/entities/reading_session.dart';
import '../entities/remote_reading_session.dart';
import '../entities/sync_metadata.dart';
import '../repositories/remote_reading_sessions_repository.dart';
import '../repositories/sync_metadata_repository.dart';

typedef LocalReadingSessionLoader =
    Future<ReadingSession?> Function(String localId);
typedef RemoteReadingSessionIdGenerator = String Function();

class SyncPendingReadingSessionsResult {
  const SyncPendingReadingSessionsResult({
    required this.pendingReadingSessions,
    required this.synced,
    required this.failed,
    required this.ignored,
  });

  final int pendingReadingSessions;
  final int synced;
  final int failed;
  final int ignored;
}

class SyncPendingReadingSessionsToSupabase {
  SyncPendingReadingSessionsToSupabase({
    required SyncMetadataRepository metadataRepository,
    required RemoteReadingSessionsRepository remoteReadingSessionsRepository,
    required LocalReadingSessionLoader loadSession,
    RemoteReadingSessionIdGenerator? remoteIdGenerator,
  }) : _metadataRepository = metadataRepository,
       _remoteReadingSessionsRepository = remoteReadingSessionsRepository,
       _loadSession = loadSession,
       _remoteIdGenerator = remoteIdGenerator ?? const Uuid().v4;

  final SyncMetadataRepository _metadataRepository;
  final RemoteReadingSessionsRepository _remoteReadingSessionsRepository;
  final LocalReadingSessionLoader _loadSession;
  final RemoteReadingSessionIdGenerator _remoteIdGenerator;

  Future<SyncPendingReadingSessionsResult> call({
    required String userId,
  }) async {
    final pending = await _metadataRepository.getPendingSync();
    final pendingReadingSessions = pending
        .where(
          (metadata) => metadata.entityType == SyncEntityType.readingSession,
        )
        .toList();

    var synced = 0;
    var failed = 0;

    for (final metadata in pendingReadingSessions) {
      try {
        switch (metadata.pendingOperation) {
          case PendingSyncOperation.create:
          case PendingSyncOperation.update:
            await _syncReadingSessionUpsert(metadata: metadata, userId: userId);
            synced++;
            break;
          case PendingSyncOperation.delete:
            await _syncReadingSessionDelete(metadata: metadata, userId: userId);
            synced++;
            break;
          case PendingSyncOperation.none:
            break;
        }
      } catch (error) {
        failed++;
        await _metadataRepository.registerFailure(
          entityType: metadata.entityType,
          localId: metadata.localId,
          message: error.toString(),
        );
      }
    }

    return SyncPendingReadingSessionsResult(
      pendingReadingSessions: pendingReadingSessions.length,
      synced: synced,
      failed: failed,
      ignored: pending.length - pendingReadingSessions.length,
    );
  }

  Future<void> _syncReadingSessionUpsert({
    required SyncMetadata metadata,
    required String userId,
  }) async {
    final session = await _loadSession(metadata.localId);
    if (session == null) {
      throw StateError('Local reading session not found: ${metadata.localId}');
    }

    final bookMetadata = await _metadataRepository.getByLocalId(
      entityType: SyncEntityType.book,
      localId: session.bookId,
    );
    final remoteBookId = bookMetadata?.remoteId;
    if (remoteBookId == null) {
      throw StateError(
        'Remote book id not found for reading session: ${metadata.localId}',
      );
    }

    final fallbackRemoteId = metadata.remoteId ?? _remoteIdGenerator();
    final remoteSession = _remoteReadingSessionFromLocal(
      session,
      userId: userId,
      remoteId: fallbackRemoteId,
      remoteBookId: remoteBookId,
    );

    final syncedSessions = await _remoteReadingSessionsRepository
        .upsertReadingSessions([remoteSession]);
    final syncedSession = syncedSessions.isEmpty
        ? remoteSession
        : syncedSessions.first;

    await _metadataRepository.markSynced(
      entityType: metadata.entityType,
      localId: metadata.localId,
      remoteId: syncedSession.id,
      lastRemoteUpdate: syncedSession.updatedAt,
    );
  }

  Future<void> _syncReadingSessionDelete({
    required SyncMetadata metadata,
    required String userId,
  }) async {
    final remoteId = metadata.remoteId;

    if (remoteId != null) {
      await _remoteReadingSessionsRepository.deleteReadingSession(
        userId: userId,
        remoteSessionId: remoteId,
      );
    }

    await _metadataRepository.markSynced(
      entityType: metadata.entityType,
      localId: metadata.localId,
      remoteId: remoteId,
    );
  }
}

RemoteReadingSession _remoteReadingSessionFromLocal(
  ReadingSession session, {
  required String userId,
  required String remoteId,
  required String remoteBookId,
}) {
  return RemoteReadingSession(
    id: remoteId,
    userId: userId,
    localSessionId: session.id,
    localBookId: session.bookId,
    remoteBookId: remoteBookId,
    pagesRead: session.pagesRead,
    minutesRead: session.minutes,
    note: session.note,
    sessionDate: session.date,
    createdAt: session.createdAt,
    updatedAt: session.updatedAt,
  );
}
