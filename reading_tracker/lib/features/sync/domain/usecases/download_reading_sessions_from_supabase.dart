import '../../../books/domain/entities/book.dart';
import '../../../reading_sessions/domain/entities/reading_session.dart';
import '../entities/remote_reading_session.dart';
import '../entities/sync_metadata.dart';
import '../repositories/remote_reading_sessions_repository.dart';
import '../repositories/sync_metadata_repository.dart';

typedef LocalBookLookup = Future<Book?> Function(String localId);
typedef LocalReadingSessionReader =
    Future<ReadingSession?> Function(String localId);
typedef LocalReadingSessionWriter =
    Future<void> Function(ReadingSession session);

class DownloadReadingSessionsResult {
  const DownloadReadingSessionsResult({
    required this.remoteReadingSessions,
    required this.applied,
    required this.skipped,
    required this.failed,
  });

  final int remoteReadingSessions;
  final int applied;
  final int skipped;
  final int failed;
}

class DownloadReadingSessionsFromSupabase {
  const DownloadReadingSessionsFromSupabase({
    required RemoteReadingSessionsRepository remoteReadingSessionsRepository,
    required SyncMetadataRepository metadataRepository,
    required LocalBookLookup readLocalBook,
    required LocalReadingSessionReader readLocalSession,
    required LocalReadingSessionWriter writeLocalSession,
  }) : _remoteReadingSessionsRepository = remoteReadingSessionsRepository,
       _metadataRepository = metadataRepository,
       _readLocalBook = readLocalBook,
       _readLocalSession = readLocalSession,
       _writeLocalSession = writeLocalSession;

  final RemoteReadingSessionsRepository _remoteReadingSessionsRepository;
  final SyncMetadataRepository _metadataRepository;
  final LocalBookLookup _readLocalBook;
  final LocalReadingSessionReader _readLocalSession;
  final LocalReadingSessionWriter _writeLocalSession;

  Future<DownloadReadingSessionsResult> call({required String userId}) async {
    final remoteSessions = await _remoteReadingSessionsRepository
        .getReadingSessions(userId: userId, includeDeleted: false);

    var applied = 0;
    var skipped = 0;
    var failed = 0;

    for (final remoteSession in remoteSessions) {
      if (remoteSession.deletedAt != null) {
        skipped++;
        continue;
      }

      try {
        final localId = remoteSession.localSessionId;
        final metadata = await _metadataRepository.getByLocalId(
          entityType: SyncEntityType.readingSession,
          localId: localId,
        );
        if (metadata?.hasPendingOperation ?? false) {
          skipped++;
          continue;
        }

        final book = await _readLocalBook(remoteSession.localBookId);
        if (book == null) {
          skipped++;
          continue;
        }

        final existing = await _readLocalSession(localId);
        await _writeLocalSession(
          _sessionFromRemote(remoteSession, existing: existing),
        );
        await _metadataRepository.markSynced(
          entityType: SyncEntityType.readingSession,
          localId: localId,
          remoteId: remoteSession.id,
          lastRemoteUpdate: remoteSession.updatedAt,
        );
        applied++;
      } catch (_) {
        failed++;
      }
    }

    return DownloadReadingSessionsResult(
      remoteReadingSessions: remoteSessions.length,
      applied: applied,
      skipped: skipped,
      failed: failed,
    );
  }
}

ReadingSession _sessionFromRemote(
  RemoteReadingSession remoteSession, {
  ReadingSession? existing,
}) {
  return ReadingSession(
    id: remoteSession.localSessionId,
    bookId: remoteSession.localBookId,
    date: remoteSession.sessionDate,
    minutes: remoteSession.minutesRead,
    pagesRead: remoteSession.pagesRead,
    note: remoteSession.note,
    createdAt: remoteSession.createdAt ?? existing?.createdAt ?? DateTime.now(),
    updatedAt: remoteSession.updatedAt ?? existing?.updatedAt,
  );
}
