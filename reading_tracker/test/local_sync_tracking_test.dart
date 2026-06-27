import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/core/database/app_database.dart';
import 'package:reading_tracker/core/preferences/reader_profile_controller.dart';
import 'package:reading_tracker/features/books/data/repositories/book_repository_impl.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/reading_sessions/data/repositories/reading_session_repository_impl.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/stats/data/repositories/drift_annual_reading_goal_repository.dart';
import 'package:reading_tracker/features/stats/domain/usecases/save_annual_reading_goal.dart';
import 'package:reading_tracker/features/sync/data/repositories/local_sync_metadata_repository.dart';
import 'package:reading_tracker/features/sync/domain/entities/sync_metadata.dart';
import 'package:reading_tracker/features/sync/domain/services/local_sync_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late LocalSyncMetadataRepository syncRepository;
  late LocalSyncTracker syncTracker;
  var syncId = 0;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.forTesting(NativeDatabase.memory());
    syncRepository = LocalSyncMetadataRepository(database.syncMetadataDao);
    syncTracker = LocalSyncTracker(
      syncRepository,
      idGenerator: () => 'sync-${++syncId}',
      clock: () => DateTime(2026, 6, 27, 10),
    );
  });

  tearDown(() => database.close());

  test('creating a book marks it as pending upload', () async {
    final repository = BookRepositoryImpl(database, syncTracker: syncTracker);

    await repository.addBook(_book(id: 'book-1'));

    final metadata = await syncMetadata(
      syncRepository,
      entityType: SyncEntityType.book,
      localId: 'book-1',
    );
    expect(metadata!.syncStatus, SyncStatus.pendingUpload);
    expect(metadata.pendingOperation, PendingSyncOperation.create);
  });

  test('editing a book marks it as pending update', () async {
    await BookRepositoryImpl(database).addBook(_book(id: 'book-1'));
    final repository = BookRepositoryImpl(database, syncTracker: syncTracker);

    await repository.updateBook(
      _book(id: 'book-1').copyWith(title: 'Updated book'),
    );

    final metadata = await syncMetadata(
      syncRepository,
      entityType: SyncEntityType.book,
      localId: 'book-1',
    );
    expect(metadata!.syncStatus, SyncStatus.pendingUpdate);
    expect(metadata.pendingOperation, PendingSyncOperation.update);
  });

  test('deleting a book marks it as pending delete', () async {
    await BookRepositoryImpl(database).addBook(_book(id: 'book-1'));
    final repository = BookRepositoryImpl(database, syncTracker: syncTracker);

    await repository.deleteBook('book-1');

    final metadata = await syncMetadata(
      syncRepository,
      entityType: SyncEntityType.book,
      localId: 'book-1',
    );
    expect(metadata!.syncStatus, SyncStatus.pendingDelete);
    expect(metadata.pendingOperation, PendingSyncOperation.delete);
  });

  test('creating a reading session marks it as pending upload', () async {
    final repository = ReadingSessionRepositoryImpl(
      database,
      syncTracker: syncTracker,
    );

    await repository.addSession(_session(id: 'session-1'));

    final metadata = await syncMetadata(
      syncRepository,
      entityType: SyncEntityType.readingSession,
      localId: 'session-1',
    );
    expect(metadata!.syncStatus, SyncStatus.pendingUpload);
    expect(metadata.pendingOperation, PendingSyncOperation.create);
  });

  test('updating annual goal marks it as pending update', () async {
    final repository = DriftAnnualReadingGoalRepository(database);
    final useCase = SaveAnnualReadingGoal(repository, syncTracker: syncTracker);

    await useCase(12);
    await useCase(24);

    final metadata = await syncMetadata(
      syncRepository,
      entityType: SyncEntityType.annualGoal,
      localId: LocalSyncTracker.annualGoalLocalId,
    );
    expect(metadata!.syncStatus, SyncStatus.pendingUpdate);
    expect(metadata.pendingOperation, PendingSyncOperation.update);
  });

  test('updating reader profile marks it as pending update', () async {
    final controller = ReaderProfileController(syncTracker: syncTracker);

    final error = await controller.updateName('Patricia');

    expect(error, isNull);
    final metadata = await syncMetadata(
      syncRepository,
      entityType: SyncEntityType.profile,
      localId: LocalSyncTracker.readerProfileLocalId,
    );
    expect(metadata!.syncStatus, SyncStatus.pendingUpdate);
    expect(metadata.pendingOperation, PendingSyncOperation.update);
  });

  test(
    'local sync tracking does not require remote Supabase components',
    () async {
      final repository = BookRepositoryImpl(database, syncTracker: syncTracker);

      await repository.addBook(_book(id: 'book-1'));
      final pending = await syncRepository.getPendingSync();

      expect(pending, hasLength(1));
      expect(pending.single.entityType, SyncEntityType.book);
    },
  );
}

Future<SyncMetadata?> syncMetadata(
  LocalSyncMetadataRepository repository, {
  required SyncEntityType entityType,
  required String localId,
}) {
  return repository.getByLocalId(entityType: entityType, localId: localId);
}

Book _book({required String id}) {
  return Book(id: id, title: 'Book $id', createdAt: DateTime(2026, 6, 27));
}

ReadingSession _session({required String id}) {
  return ReadingSession(
    id: id,
    bookId: 'book-1',
    date: DateTime(2026, 6, 27),
    minutes: 20,
    pagesRead: 12,
    createdAt: DateTime(2026, 6, 27),
  );
}
