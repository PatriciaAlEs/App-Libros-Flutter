import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_tracker/core/preferences/reader_profile_controller.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/sync/data/repositories/manual_annual_goal_sync_provider.dart';
import 'package:reading_tracker/features/sync/data/repositories/manual_books_sync_provider.dart';
import 'package:reading_tracker/features/sync/data/repositories/manual_reader_profile_sync_provider.dart';
import 'package:reading_tracker/features/sync/data/repositories/manual_reading_sessions_sync_provider.dart';
import 'package:reading_tracker/features/sync/data/repositories/sync_orchestrator_provider.dart';
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
import 'package:reading_tracker/features/sync/domain/services/sync_orchestrator.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_annual_goal_to_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_books_to_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_reader_profile_to_supabase.dart';
import 'package:reading_tracker/features/sync/domain/usecases/sync_pending_reading_sessions_to_supabase.dart';

void main() {
  test('runs books sync with the provided user id', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _metadata(localId: 'book-1'),
    ]);
    final remoteRepository = FakeRemoteBooksRepository();
    final syncBooks = SyncPendingBooksToSupabase(
      metadataRepository: metadataRepository,
      remoteBooksRepository: remoteRepository,
      loadBook: (localId) async => _book(id: localId),
      remoteIdGenerator: () => 'remote-book-1',
    );
    final orchestrator = SyncOrchestrator(
      syncBooks: syncBooks,
      syncReadingSessions: _emptyReadingSessionsSync(),
      syncReaderProfile: _emptyReaderProfileSync(),
      syncAnnualGoal: _emptyAnnualGoalSync(),
    );

    final result = await orchestrator.runManualSync(userId: 'user-1');

    expect(remoteRepository.userIds, ['user-1']);
    expect(result.books.pendingBooks, 1);
    expect(result.synced, 1);
    expect(result.failed, 0);
    expect(result.ignored, 0);
  });

  test('returns aggregate counters from the books sync result', () async {
    final metadataRepository = FakeSyncMetadataRepository([
      _metadata(localId: 'book-1'),
      _metadata(
        entityType: SyncEntityType.readingSession,
        localId: 'session-1',
      ),
      _metadata(entityType: SyncEntityType.profile, localId: 'reader_profile'),
      _metadata(
        entityType: SyncEntityType.annualGoal,
        localId: 'annualReadingGoal',
      ),
    ]);
    final remoteRepository = FakeRemoteBooksRepository();
    final syncBooks = SyncPendingBooksToSupabase(
      metadataRepository: metadataRepository,
      remoteBooksRepository: remoteRepository,
      loadBook: (localId) async => _book(id: localId),
      remoteIdGenerator: () => 'remote-book-1',
    );
    final syncReadingSessions = SyncPendingReadingSessionsToSupabase(
      metadataRepository: metadataRepository,
      remoteReadingSessionsRepository: FakeRemoteReadingSessionsRepository(),
      loadSession: (localId) async => _session(id: localId),
      remoteIdGenerator: () => 'remote-session-1',
    );
    final orchestrator = SyncOrchestrator(
      syncBooks: syncBooks,
      syncReadingSessions: syncReadingSessions,
      syncReaderProfile: SyncPendingReaderProfileToSupabase(
        metadataRepository: metadataRepository,
        remoteProfileRepository: FakeRemoteProfileRepository(),
        loadProfile: () async => const ReaderProfile(),
      ),
      syncAnnualGoal: SyncPendingAnnualGoalToSupabase(
        metadataRepository: metadataRepository,
        remoteAnnualGoalsRepository: FakeRemoteAnnualGoalsRepository(),
        loadAnnualGoal: () async => 24,
        remoteIdGenerator: () => 'remote-goal-1',
        clock: () => DateTime(2026, 7),
      ),
    );

    final result = await orchestrator.runManualSync(userId: 'user-1');

    expect(result.books.synced, 1);
    expect(result.books.failed, 0);
    expect(result.books.ignored, 3);
    expect(result.readingSessions.synced, 1);
    expect(result.readingSessions.failed, 0);
    expect(result.readingSessions.ignored, 3);
    expect(result.readerProfile.synced, 1);
    expect(result.readerProfile.failed, 0);
    expect(result.readerProfile.ignored, 3);
    expect(result.annualGoal.synced, 1);
    expect(result.annualGoal.failed, 0);
    expect(result.annualGoal.ignored, 3);
    expect(result.synced, 4);
    expect(result.failed, 0);
    expect(result.ignored, 12);
  });

  test('propagates a full books sync failure', () async {
    final syncBooks = SyncPendingBooksToSupabase(
      metadataRepository: ThrowingSyncMetadataRepository(),
      remoteBooksRepository: FakeRemoteBooksRepository(),
      loadBook: (_) async => null,
    );
    final orchestrator = SyncOrchestrator(
      syncBooks: syncBooks,
      syncReadingSessions: _emptyReadingSessionsSync(),
      syncReaderProfile: _emptyReaderProfileSync(),
      syncAnnualGoal: _emptyAnnualGoalSync(),
    );

    await expectLater(
      orchestrator.runManualSync(userId: 'user-1'),
      throwsA(isA<StateError>()),
    );
  });

  test('runs books before reading sessions', () async {
    final operations = <String>[];
    final metadataRepository = FakeSyncMetadataRepository([
      _metadata(localId: 'book-1'),
      _metadata(
        entityType: SyncEntityType.readingSession,
        localId: 'session-1',
      ),
      _metadata(entityType: SyncEntityType.profile, localId: 'reader_profile'),
      _metadata(
        entityType: SyncEntityType.annualGoal,
        localId: 'annualReadingGoal',
      ),
    ]);
    final syncBooks = SyncPendingBooksToSupabase(
      metadataRepository: metadataRepository,
      remoteBooksRepository: FakeRemoteBooksRepository(operations: operations),
      loadBook: (localId) async => _book(id: localId),
      remoteIdGenerator: () => 'remote-book-1',
    );
    final syncReadingSessions = SyncPendingReadingSessionsToSupabase(
      metadataRepository: metadataRepository,
      remoteReadingSessionsRepository: FakeRemoteReadingSessionsRepository(
        operations: operations,
      ),
      loadSession: (localId) async => _session(id: localId),
      remoteIdGenerator: () => 'remote-session-1',
    );
    final orchestrator = SyncOrchestrator(
      syncBooks: syncBooks,
      syncReadingSessions: syncReadingSessions,
      syncReaderProfile: SyncPendingReaderProfileToSupabase(
        metadataRepository: metadataRepository,
        remoteProfileRepository: FakeRemoteProfileRepository(
          operations: operations,
        ),
        loadProfile: () async => const ReaderProfile(),
      ),
      syncAnnualGoal: SyncPendingAnnualGoalToSupabase(
        metadataRepository: metadataRepository,
        remoteAnnualGoalsRepository: FakeRemoteAnnualGoalsRepository(
          operations: operations,
        ),
        loadAnnualGoal: () async => 24,
        remoteIdGenerator: () => 'remote-goal-1',
        clock: () => DateTime(2026, 7),
      ),
    );

    await orchestrator.runManualSync(userId: 'user-1');

    expect(operations, [
      'books',
      'reading-sessions',
      'reader-profile',
      'annual-goal',
    ]);
  });

  test('provider returns null when books sync is unavailable', () {
    final container = ProviderContainer(
      overrides: [
        syncPendingBooksToSupabaseProvider.overrideWith((ref) => null),
        syncPendingReadingSessionsToSupabaseProvider.overrideWith(
          (ref) => _emptyReadingSessionsSync(),
        ),
        syncPendingReaderProfileToSupabaseProvider.overrideWith(
          (ref) => _emptyReaderProfileSync(),
        ),
        syncPendingAnnualGoalToSupabaseProvider.overrideWith(
          (ref) => _emptyAnnualGoalSync(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(syncOrchestratorProvider), isNull);
  });

  test('provider returns null when reading sessions sync is unavailable', () {
    final container = ProviderContainer(
      overrides: [
        syncPendingBooksToSupabaseProvider.overrideWith(
          (ref) => _emptyBooksSync(),
        ),
        syncPendingReadingSessionsToSupabaseProvider.overrideWith(
          (ref) => null,
        ),
        syncPendingReaderProfileToSupabaseProvider.overrideWith(
          (ref) => _emptyReaderProfileSync(),
        ),
        syncPendingAnnualGoalToSupabaseProvider.overrideWith(
          (ref) => _emptyAnnualGoalSync(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(syncOrchestratorProvider), isNull);
  });

  test('provider returns null when reader profile sync is unavailable', () {
    final container = ProviderContainer(
      overrides: [
        syncPendingBooksToSupabaseProvider.overrideWith(
          (ref) => _emptyBooksSync(),
        ),
        syncPendingReadingSessionsToSupabaseProvider.overrideWith(
          (ref) => _emptyReadingSessionsSync(),
        ),
        syncPendingReaderProfileToSupabaseProvider.overrideWith((ref) => null),
        syncPendingAnnualGoalToSupabaseProvider.overrideWith(
          (ref) => _emptyAnnualGoalSync(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(syncOrchestratorProvider), isNull);
  });

  test('provider returns null when annual goal sync is unavailable', () {
    final container = ProviderContainer(
      overrides: [
        syncPendingBooksToSupabaseProvider.overrideWith(
          (ref) => _emptyBooksSync(),
        ),
        syncPendingReadingSessionsToSupabaseProvider.overrideWith(
          (ref) => _emptyReadingSessionsSync(),
        ),
        syncPendingReaderProfileToSupabaseProvider.overrideWith(
          (ref) => _emptyReaderProfileSync(),
        ),
        syncPendingAnnualGoalToSupabaseProvider.overrideWith((ref) => null),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(syncOrchestratorProvider), isNull);
  });
}

Book _book({required String id}) {
  return Book(id: id, title: 'Book $id', createdAt: DateTime(2026, 7));
}

ReadingSession _session({required String id}) {
  return ReadingSession(
    id: id,
    bookId: 'book-1',
    date: DateTime(2026, 7),
    minutes: 30,
    pagesRead: 12,
    createdAt: DateTime(2026, 7),
  );
}

SyncMetadata _metadata({
  SyncEntityType entityType = SyncEntityType.book,
  required String localId,
}) {
  final now = DateTime(2026, 7);
  return SyncMetadata(
    id: 'sync-$localId',
    entityType: entityType,
    localId: localId,
    remoteId: entityType == SyncEntityType.book ? 'remote-book-1' : null,
    syncStatus: SyncStatus.pendingUpload,
    pendingOperation: PendingSyncOperation.create,
    createdAt: now,
    updatedAt: now,
  );
}

class FakeRemoteBooksRepository implements RemoteBooksRepository {
  FakeRemoteBooksRepository({this.operations});

  final List<String>? operations;
  final List<String> userIds = [];

  @override
  Future<void> deleteBook({
    required String userId,
    required String remoteBookId,
  }) async {
    userIds.add(userId);
  }

  @override
  Future<List<RemoteBook>> getBooks({
    required String userId,
    DateTime? updatedAfter,
    bool includeDeleted = false,
  }) async {
    return const [];
  }

  @override
  Future<List<RemoteBook>> upsertBooks(List<RemoteBook> books) async {
    operations?.add('books');
    userIds.add(books.single.userId);
    return books;
  }
}

class FakeRemoteReadingSessionsRepository
    implements RemoteReadingSessionsRepository {
  FakeRemoteReadingSessionsRepository({this.operations});

  final List<String>? operations;

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
    return const [];
  }

  @override
  Future<List<RemoteReadingSession>> upsertReadingSessions(
    List<RemoteReadingSession> sessions,
  ) async {
    operations?.add('reading-sessions');
    return sessions;
  }
}

class FakeRemoteProfileRepository implements RemoteProfileRepository {
  FakeRemoteProfileRepository({this.operations});

  final List<String>? operations;

  @override
  Future<void> deleteProfile(String userId) async {}

  @override
  Future<RemoteProfile?> getProfile(String userId) async {
    return null;
  }

  @override
  Future<RemoteProfile> upsertProfile(RemoteProfile profile) async {
    operations?.add('reader-profile');
    return profile;
  }
}

class FakeRemoteAnnualGoalsRepository implements RemoteAnnualGoalsRepository {
  FakeRemoteAnnualGoalsRepository({this.operations});

  final List<String>? operations;

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
    return const [];
  }

  @override
  Future<List<RemoteAnnualGoal>> upsertAnnualGoals(
    List<RemoteAnnualGoal> goals,
  ) async {
    operations?.add('annual-goal');
    return goals;
  }
}

class FakeSyncMetadataRepository implements SyncMetadataRepository {
  FakeSyncMetadataRepository(this.pending);

  final List<SyncMetadata> pending;

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
    for (final item in pending) {
      if (item.entityType == entityType && item.localId == localId) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<List<SyncMetadata>> getPendingSync() async => pending;

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
  }) async {}

  @override
  Future<void> registerFailure({
    required SyncEntityType entityType,
    required String localId,
    required String message,
  }) async {}

  @override
  Future<void> save(SyncMetadata metadata) async {}
}

SyncPendingBooksToSupabase _emptyBooksSync() {
  return SyncPendingBooksToSupabase(
    metadataRepository: FakeSyncMetadataRepository(const []),
    remoteBooksRepository: FakeRemoteBooksRepository(),
    loadBook: (_) async => null,
  );
}

SyncPendingReadingSessionsToSupabase _emptyReadingSessionsSync() {
  return SyncPendingReadingSessionsToSupabase(
    metadataRepository: FakeSyncMetadataRepository(const []),
    remoteReadingSessionsRepository: FakeRemoteReadingSessionsRepository(),
    loadSession: (_) async => null,
  );
}

SyncPendingReaderProfileToSupabase _emptyReaderProfileSync() {
  return SyncPendingReaderProfileToSupabase(
    metadataRepository: FakeSyncMetadataRepository(const []),
    remoteProfileRepository: FakeRemoteProfileRepository(),
    loadProfile: () async => const ReaderProfile(),
  );
}

SyncPendingAnnualGoalToSupabase _emptyAnnualGoalSync() {
  return SyncPendingAnnualGoalToSupabase(
    metadataRepository: FakeSyncMetadataRepository(const []),
    remoteAnnualGoalsRepository: FakeRemoteAnnualGoalsRepository(),
    loadAnnualGoal: () async => null,
  );
}

class ThrowingSyncMetadataRepository extends FakeSyncMetadataRepository {
  ThrowingSyncMetadataRepository() : super(const []);

  @override
  Future<List<SyncMetadata>> getPendingSync() {
    throw StateError('Books sync failed before processing records');
  }
}
