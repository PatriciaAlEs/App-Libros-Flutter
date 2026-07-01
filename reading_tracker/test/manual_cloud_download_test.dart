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

  test('pending local and newer remote book marks conflict', () async {
    final metadataRepository = FakeSyncMetadataRepository({
      'book:book-1': _metadata(
        entityType: SyncEntityType.book,
        localId: 'book-1',
        pendingOperation: PendingSyncOperation.update,
        lastRemoteUpdate: DateTime(2026, 7),
      ),
    });
    final writtenBooks = <Book>[];
    final useCase = DownloadBooksFromSupabase(
      remoteBooksRepository: FakeRemoteBooksRepository([
        _remoteBook(
          localBookId: 'book-1',
          remoteId: 'remote-book-1',
          updatedAt: DateTime(2026, 7, 2),
        ),
      ]),
      metadataRepository: metadataRepository,
      readLocalBook: (_) async => null,
      writeLocalBook: (book) async => writtenBooks.add(book),
    );

    final result = await useCase(userId: userId);

    expect(result.applied, 0);
    expect(result.skipped, 0);
    expect(result.conflicts, 1);
    expect(writtenBooks, isEmpty);
    expect(metadataRepository.syncedRemoteIds, isEmpty);
    expect(metadataRepository.conflictRemoteIds['book-1'], 'remote-book-1');
    expect(
      metadataRepository.metadata['book:book-1']!.pendingOperation,
      PendingSyncOperation.update,
    );
    expect(
      metadataRepository.metadata['book:book-1']!.syncStatus,
      SyncStatus.conflict,
    );
    expect(metadataRepository.conflictMessages['book-1'], contains('book-1'));
  });

  test('pending local and remote book without updatedAt only skips', () async {
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
    expect(result.conflicts, 0);
    expect(writtenBooks, isEmpty);
    expect(metadataRepository.conflictRemoteIds, isEmpty);
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

  test('pending local and newer remote session marks conflict', () async {
    final metadataRepository = FakeSyncMetadataRepository({
      'reading_session:session-1': _metadata(
        entityType: SyncEntityType.readingSession,
        localId: 'session-1',
        pendingOperation: PendingSyncOperation.update,
      ),
    });
    final writtenSessions = <ReadingSession>[];
    final useCase = DownloadReadingSessionsFromSupabase(
      remoteReadingSessionsRepository: FakeRemoteReadingSessionsRepository([
        _remoteSession(
          localSessionId: 'session-1',
          localBookId: 'book-1',
          updatedAt: DateTime(2026, 7, 2),
        ),
      ]),
      metadataRepository: metadataRepository,
      readLocalBook: (localId) async =>
          Book(id: localId, title: 'Book', createdAt: DateTime(2026, 7)),
      readLocalSession: (_) async => null,
      writeLocalSession: (session) async => writtenSessions.add(session),
    );

    final result = await useCase(userId: userId);

    expect(result.applied, 0);
    expect(result.conflicts, 1);
    expect(writtenSessions, isEmpty);
    expect(metadataRepository.conflictRemoteIds['session-1'], 'remote-session');
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

  test('pending local and newer remote profile marks conflict', () async {
    final metadataRepository = FakeSyncMetadataRepository({
      'profile:${LocalSyncTracker.readerProfileLocalId}': _metadata(
        entityType: SyncEntityType.profile,
        localId: LocalSyncTracker.readerProfileLocalId,
        pendingOperation: PendingSyncOperation.update,
      ),
    });
    var wroteProfile = false;
    final useCase = DownloadReaderProfileFromSupabase(
      remoteProfileRepository: FakeRemoteProfileRepository(
        RemoteProfile(
          id: userId,
          readerName: 'Cloud',
          updatedAt: DateTime(2026, 7, 2),
        ),
      ),
      metadataRepository: metadataRepository,
      readLocalProfile: () async => const ReaderProfile(name: 'Local'),
      writeLocalProfile: (_) async => wroteProfile = true,
    );

    final result = await useCase(userId: userId);

    expect(result.applied, 0);
    expect(result.skipped, 0);
    expect(result.conflicts, 1);
    expect(wroteProfile, isFalse);
    expect(
      metadataRepository.conflictRemoteIds[LocalSyncTracker
          .readerProfileLocalId],
      userId,
    );
  });

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

  test('pending local and newer remote annual goal marks conflict', () async {
    final metadataRepository = FakeSyncMetadataRepository({
      'annual_goal:${LocalSyncTracker.annualGoalLocalId}': _metadata(
        entityType: SyncEntityType.annualGoal,
        localId: LocalSyncTracker.annualGoalLocalId,
        pendingOperation: PendingSyncOperation.update,
      ),
    });
    final writtenGoals = <int>[];
    final useCase = DownloadAnnualGoalFromSupabase(
      remoteAnnualGoalsRepository: FakeRemoteAnnualGoalsRepository([
        _remoteAnnualGoal(
          year: 2026,
          targetBooks: 24,
          remoteId: 'goal-2026',
          updatedAt: DateTime(2026, 7, 2),
        ),
      ]),
      metadataRepository: metadataRepository,
      writeAnnualGoal: (goal) async => writtenGoals.add(goal),
      clock: () => DateTime(2026, 7),
    );

    final result = await useCase(userId: userId);

    expect(result.applied, 0);
    expect(result.conflicts, 1);
    expect(writtenGoals, isEmpty);
    expect(
      metadataRepository.conflictRemoteIds[LocalSyncTracker.annualGoalLocalId],
      'goal-2026',
    );
  });
}

RemoteBook _remoteBook({
  String localBookId = 'book-1',
  String remoteId = 'remote-book',
  DateTime? updatedAt,
  DateTime? deletedAt,
}) {
  return RemoteBook(
    id: remoteId,
    userId: 'user-1',
    localBookId: localBookId,
    title: 'Cloud Book',
    status: 'reading',
    createdAt: DateTime(2026, 7),
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

RemoteReadingSession _remoteSession({
  required String localSessionId,
  required String localBookId,
  DateTime? updatedAt,
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
    updatedAt: updatedAt,
  );
}

RemoteAnnualGoal _remoteAnnualGoal({
  required int year,
  required int targetBooks,
  String remoteId = 'remote-goal',
  DateTime? updatedAt,
}) {
  return RemoteAnnualGoal(
    id: remoteId,
    userId: 'user-1',
    localGoalId: LocalSyncTracker.annualGoalLocalId,
    year: year,
    targetBooks: targetBooks,
    updatedAt: updatedAt,
  );
}

SyncMetadata _metadata({
  required SyncEntityType entityType,
  required String localId,
  required PendingSyncOperation pendingOperation,
  DateTime? lastRemoteUpdate,
}) {
  final now = DateTime(2026, 7);
  return SyncMetadata(
    id: 'sync-$localId',
    entityType: entityType,
    localId: localId,
    syncStatus: SyncStatus.pendingUpdate,
    pendingOperation: pendingOperation,
    lastRemoteUpdate: lastRemoteUpdate,
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
  final Map<String, String> conflictRemoteIds = {};
  final Map<String, String> conflictMessages = {};

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
  Future<void> markConflict({
    required SyncEntityType entityType,
    required String localId,
    required String remoteId,
    required DateTime lastRemoteUpdate,
    required String message,
  }) async {
    final key = '${entityType.value}:$localId';
    final existing = metadata[key]!;
    metadata[key] = SyncMetadata(
      id: existing.id,
      entityType: existing.entityType,
      localId: existing.localId,
      remoteId: remoteId,
      syncStatus: SyncStatus.conflict,
      pendingOperation: existing.pendingOperation,
      lastSyncedAt: existing.lastSyncedAt,
      lastLocalUpdate: existing.lastLocalUpdate,
      lastRemoteUpdate: lastRemoteUpdate,
      errorMessage: message,
      retryCount: existing.retryCount,
      createdAt: existing.createdAt,
      updatedAt: DateTime(2026, 7, 3),
    );
    conflictRemoteIds[localId] = remoteId;
    conflictMessages[localId] = message;
  }

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
