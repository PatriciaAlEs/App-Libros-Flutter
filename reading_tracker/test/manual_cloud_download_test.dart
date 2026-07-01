import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/core/preferences/reader_profile_controller.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/sync/domain/entities/remote_annual_goal.dart';
import 'package:reading_tracker/features/sync/domain/entities/remote_book.dart';
import 'package:reading_tracker/features/sync/domain/entities/remote_profile.dart';
import 'package:reading_tracker/features/sync/domain/entities/remote_reading_session.dart';
import 'package:reading_tracker/features/sync/domain/entities/sync_metadata.dart';
import 'package:reading_tracker/features/sync/domain/repositories/remote_annual_goals_repository.dart';
import 'package:reading_tracker/features/sync/domain/repositories/remote_books_repository.dart';
import 'package:reading_tracker/features/sync/domain/repositories/remote_profile_repository.dart';
import 'package:reading_tracker/features/sync/domain/repositories/remote_reading_sessions_repository.dart';
import 'package:reading_tracker/features/sync/domain/repositories/sync_metadata_repository.dart';
import 'package:reading_tracker/features/sync/domain/services/local_sync_tracker.dart';
import 'package:reading_tracker/features/sync/domain/usecases/download_annual_goal_from_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/download_books_from_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/download_reader_profile_from_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/download_reading_sessions_from_supabase.dart';

void main() {
  const userId = 'user-1';

  test(
    'downloads books and marks metadata as synced when local is clean',
    () async {
      final metadataRepository = FakeSyncMetadataRepository();
      final writtenBooks = <Book>[];
      final useCase = DownloadBooksFromSupabase(
        remoteBooksRepository: FakeRemoteBooksRepository([
          _remoteBook(localBookId: 'book-1', remoteId: 'remote-book-1'),
        ]),
        metadataRepository: metadataRepository,
        readLocalBook: (_) async => null,
        writeLocalBook: (book) async => writtenBooks.add(book),
      );

      final result = await useCase(userId: userId);

      expect(result.applied, 1);
      expect(result.skipped, 0);
      expect(writtenBooks.single.id, 'book-1');
      expect(writtenBooks.single.title, 'Cloud Book');
      expect(metadataRepository.syncedRemoteIds['book-1'], 'remote-book-1');
    },
  );

  test('skips books with pending local metadata', () async {
    final metadataRepository = FakeSyncMetadataRepository({
      'book:book-1': _metadata(
        entityType: SyncEntityType.book,
        localId: 'book-1',
        pendingOperation: PendingSyncOperation.update,
      ),
    });
    final writtenBooks = <Book>[];
    final useCase = DownloadBooksFromSupabase(
      remoteBooksRepository: FakeRemoteBooksRepository([
        _remoteBook(localBookId: 'book-1'),
      ]),
      metadataRepository: metadataRepository,
      readLocalBook: (_) async => null,
      writeLocalBook: (book) async => writtenBooks.add(book),
    );

    final result = await useCase(userId: userId);

    expect(result.applied, 0);
    expect(result.skipped, 1);
    expect(writtenBooks, isEmpty);
    expect(metadataRepository.syncedRemoteIds, isEmpty);
  });

  test('does not process deleted remote books', () async {
    final metadataRepository = FakeSyncMetadataRepository();
    final writtenBooks = <Book>[];
    final useCase = DownloadBooksFromSupabase(
      remoteBooksRepository: FakeRemoteBooksRepository([
        _remoteBook(localBookId: 'book-1', deletedAt: DateTime(2026, 7, 2)),
      ]),
      metadataRepository: metadataRepository,
      readLocalBook: (_) async => null,
      writeLocalBook: (book) async => writtenBooks.add(book),
    );

    final result = await useCase(userId: userId);

    expect(result.applied, 0);
    expect(result.skipped, 1);
    expect(writtenBooks, isEmpty);
  });

  test('downloads reading sessions only when local book exists', () async {
    final metadataRepository = FakeSyncMetadataRepository();
    final writtenSessions = <ReadingSession>[];
    final useCase = DownloadReadingSessionsFromSupabase(
      remoteReadingSessionsRepository: FakeRemoteReadingSessionsRepository([
        _remoteSession(localSessionId: 'session-1', localBookId: 'book-1'),
        _remoteSession(localSessionId: 'session-2', localBookId: 'missing'),
      ]),
      metadataRepository: metadataRepository,
      readLocalBook: (localId) async => localId == 'book-1'
          ? Book(id: localId, title: 'Book', createdAt: DateTime(2026, 7))
          : null,
      readLocalSession: (_) async => null,
      writeLocalSession: (session) async => writtenSessions.add(session),
    );

    final result = await useCase(userId: userId);

    expect(result.applied, 1);
    expect(result.skipped, 1);
    expect(writtenSessions.single.id, 'session-1');
    expect(metadataRepository.syncedRemoteIds['session-1'], 'remote-session');
  });

  test(
    'downloads reader profile without clearing current reading book',
    () async {
      final metadataRepository = FakeSyncMetadataRepository();
      late ReaderProfile writtenProfile;
      final useCase = DownloadReaderProfileFromSupabase(
        remoteProfileRepository: const FakeRemoteProfileRepository(
          RemoteProfile(
            id: userId,
            readerName: 'Patricia',
            greeting: 'custom',
            customGreeting: 'Hola',
            updatedAt: null,
          ),
        ),
        metadataRepository: metadataRepository,
        readLocalProfile: () async =>
            const ReaderProfile(currentReadingBookId: 'book-1'),
        writeLocalProfile: (profile) async => writtenProfile = profile,
      );

      final result = await useCase(userId: userId);

      expect(result.applied, 1);
      expect(writtenProfile.displayName, 'Patricia');
      expect(
        writtenProfile.greetingPreference,
        ReaderGreetingPreference.custom,
      );
      expect(writtenProfile.customGreeting, 'Hola');
      expect(writtenProfile.currentReadingBookId, 'book-1');
      expect(
        metadataRepository.syncedRemoteIds[LocalSyncTracker
            .readerProfileLocalId],
        userId,
      );
    },
  );

  test('downloads annual goal only for current year', () async {
    final metadataRepository = FakeSyncMetadataRepository();
    final writtenGoals = <int>[];
    final useCase = DownloadAnnualGoalFromSupabase(
      remoteAnnualGoalsRepository: FakeRemoteAnnualGoalsRepository([
        _remoteAnnualGoal(year: 2025, targetBooks: 12),
        _remoteAnnualGoal(year: 2026, targetBooks: 24, remoteId: 'goal-2026'),
      ]),
      metadataRepository: metadataRepository,
      writeAnnualGoal: (goal) async => writtenGoals.add(goal),
      clock: () => DateTime(2026, 7),
    );

    final result = await useCase(userId: userId);

    expect(result.applied, 1);
    expect(result.skipped, 1);
    expect(writtenGoals, [24]);
    expect(
      metadataRepository.syncedRemoteIds[LocalSyncTracker.annualGoalLocalId],
      'goal-2026',
    );
  });
}

RemoteBook _remoteBook({
  String localBookId = 'book-1',
  String remoteId = 'remote-book',
  DateTime? deletedAt,
}) {
  return RemoteBook(
    id: remoteId,
    userId: 'user-1',
    localBookId: localBookId,
    title: 'Cloud Book',
    status: 'reading',
    createdAt: DateTime(2026, 7),
    updatedAt: DateTime(2026, 7, 2),
    deletedAt: deletedAt,
  );
}

RemoteReadingSession _remoteSession({
  required String localSessionId,
  required String localBookId,
}) {
  return RemoteReadingSession(
    id: 'remote-session',
    userId: 'user-1',
    localSessionId: localSessionId,
    localBookId: localBookId,
    pagesRead: 10,
    minutesRead: 20,
    sessionDate: DateTime(2026, 7),
    createdAt: DateTime(2026, 7),
  );
}

RemoteAnnualGoal _remoteAnnualGoal({
  required int year,
  required int targetBooks,
  String remoteId = 'remote-goal',
}) {
  return RemoteAnnualGoal(
    id: remoteId,
    userId: 'user-1',
    localGoalId: LocalSyncTracker.annualGoalLocalId,
    year: year,
    targetBooks: targetBooks,
  );
}

SyncMetadata _metadata({
  required SyncEntityType entityType,
  required String localId,
  required PendingSyncOperation pendingOperation,
}) {
  final now = DateTime(2026, 7);
  return SyncMetadata(
    id: 'sync-$localId',
    entityType: entityType,
    localId: localId,
    syncStatus: SyncStatus.pendingUpdate,
    pendingOperation: pendingOperation,
    createdAt: now,
    updatedAt: now,
  );
}

class FakeRemoteBooksRepository implements RemoteBooksRepository {
  const FakeRemoteBooksRepository(this.books);

  final List<RemoteBook> books;

  @override
  Future<void> deleteBook({
    required String userId,
    required String remoteBookId,
  }) async {}

  @override
  Future<List<RemoteBook>> getBooks({
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  }) async {
    return books;
  }

  @override
  Future<List<RemoteBook>> upsertBooks(List<RemoteBook> books) async {
    return books;
  }
}

class FakeRemoteReadingSessionsRepository
    implements RemoteReadingSessionsRepository {
  const FakeRemoteReadingSessionsRepository(this.sessions);

  final List<RemoteReadingSession> sessions;

  @override
  Future<void> deleteReadingSession({
    required String userId,
    required String remoteSessionId,
  }) async {}

  @override
  Future<List<RemoteReadingSession>> getReadingSessions({
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  }) async {
    return sessions;
  }

  @override
  Future<List<RemoteReadingSession>> upsertReadingSessions(
    List<RemoteReadingSession> sessions,
  ) async {
    return sessions;
  }
}

class FakeRemoteProfileRepository implements RemoteProfileRepository {
  const FakeRemoteProfileRepository(this.profile);

  final RemoteProfile? profile;

  @override
  Future<void> deleteProfile(String userId) async {}

  @override
  Future<RemoteProfile?> getProfile(String userId) async {
    return profile;
  }

  @override
  Future<RemoteProfile> upsertProfile(RemoteProfile profile) async {
    return profile;
  }
}

class FakeRemoteAnnualGoalsRepository implements RemoteAnnualGoalsRepository {
  const FakeRemoteAnnualGoalsRepository(this.goals);

  final List<RemoteAnnualGoal> goals;

  @override
  Future<void> deleteAnnualGoal({
    required String userId,
    required String goalId,
  }) async {}

  @override
  Future<List<RemoteAnnualGoal>> getAnnualGoals({
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  }) async {
    return goals;
  }

  @override
  Future<List<RemoteAnnualGoal>> upsertAnnualGoals(
    List<RemoteAnnualGoal> goals,
  ) async {
    return goals;
  }
}

class FakeSyncMetadataRepository implements SyncMetadataRepository {
  FakeSyncMetadataRepository([Map<String, SyncMetadata>? metadata])
    : metadata = metadata ?? {};

  final Map<String, SyncMetadata> metadata;
  final Map<String, String?> syncedRemoteIds = {};

  @override
  Future<void> associateRemoteId({
    required SyncEntityType entityType,
    required String localId,
    required String remoteId,
    DateTime? lastRemoteUpdate,
  }) async {}

  @override
  Future<SyncMetadata?> getByLocalId({
    required SyncEntityType entityType,
    required String localId,
  }) async {
    return metadata['${entityType.value}:$localId'];
  }

  @override
  Future<List<SyncMetadata>> getPendingSync() async {
    return metadata.values.where((item) => item.hasPendingOperation).toList();
  }

  @override
  Future<void> markPendingDelete({
    required SyncEntityType entityType,
    required String localId,
    DateTime? localUpdate,
  }) async {}

  @override
  Future<void> markPendingUpdate({
    required SyncEntityType entityType,
    required String localId,
    DateTime? localUpdate,
  }) async {}

  @override
  Future<void> markPendingUpload({
    required SyncEntityType entityType,
    required String localId,
    DateTime? localUpdate,
  }) async {}

  @override
  Future<void> markSynced({
    required SyncEntityType entityType,
    required String localId,
    String? remoteId,
    DateTime? lastRemoteUpdate,
  }) async {
    syncedRemoteIds[localId] = remoteId;
  }

  @override
  Future<void> registerFailure({
    required SyncEntityType entityType,
    required String localId,
    required String message,
  }) async {}

  @override
  Future<void> save(SyncMetadata metadata) async {}
}
