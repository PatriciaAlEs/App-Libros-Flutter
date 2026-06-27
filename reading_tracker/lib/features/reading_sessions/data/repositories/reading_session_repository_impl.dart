import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/reading_session_dao.dart';
import '../../../../core/database/database_seed.dart';
import '../../../sync/domain/services/local_sync_tracker.dart';
import '../../domain/entities/reading_session.dart';
import '../../domain/repositories/reading_session_repository.dart';
import '../mappers/reading_session_mapper.dart';

class ReadingSessionRepositoryImpl implements ReadingSessionRepository {
  ReadingSessionRepositoryImpl(
    AppDatabase database, {
    LocalSyncTracker? syncTracker,
  }) : _dao = database.readingSessionDao,
       _seeder = DatabaseSeeder(database),
       _syncTracker = syncTracker;

  final ReadingSessionDao _dao;
  final DatabaseSeeder _seeder;
  final LocalSyncTracker? _syncTracker;

  @override
  Future<void> addSession(ReadingSession session) async {
    await _seeder.seedIfNeeded();
    await _dao.insertSession(session.toCompanion());
    await _syncTracker?.trackReadingSessionCreated(session.id);
  }

  @override
  Future<void> updateSession(ReadingSession session) async {
    await _seeder.seedIfNeeded();
    await _dao.updateSession(session.toCompanion());
    await _syncTracker?.trackReadingSessionUpdated(session.id);
  }

  @override
  Future<void> deleteSession(String id) async {
    await _seeder.seedIfNeeded();
    await _dao.deleteSession(id);
    await _syncTracker?.trackReadingSessionDeleted(id);
  }

  @override
  Future<List<ReadingSession>> getSessionsForDay(DateTime day) async {
    await _seeder.seedIfNeeded();
    final rows = await _dao.getSessionsForDay(day);
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<List<ReadingSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    await _seeder.seedIfNeeded();
    final rows = await _dao.getSessionsInRange(start, end);
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<List<ReadingSession>> getSessionsForBook(String bookId) async {
    await _seeder.seedIfNeeded();
    final rows = await _dao.getSessionsForBook(bookId);
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Stream<List<ReadingSession>> watchSessionsInRange(
    DateTime start,
    DateTime end,
  ) {
    return Stream.fromFuture(_seeder.seedIfNeeded()).asyncExpand(
      (_) => _dao
          .watchSessionsInRange(start, end)
          .map((rows) => rows.map((row) => row.toDomain()).toList()),
    );
  }
}
