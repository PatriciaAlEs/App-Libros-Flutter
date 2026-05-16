import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/reading_session_dao.dart';
import '../../../../core/database/database_seed.dart';
import '../../domain/entities/reading_session.dart';
import '../../domain/repositories/reading_session_repository.dart';
import '../mappers/reading_session_mapper.dart';

class ReadingSessionRepositoryImpl implements ReadingSessionRepository {
  ReadingSessionRepositoryImpl(AppDatabase database)
    : _dao = database.readingSessionDao,
      _seeder = DatabaseSeeder(database);

  final ReadingSessionDao _dao;
  final DatabaseSeeder _seeder;

  @override
  Future<void> addSession(ReadingSession session) async {
    await _seeder.seedIfNeeded();
    await _dao.insertSession(session.toCompanion());
  }

  @override
  Future<void> updateSession(ReadingSession session) async {
    await _seeder.seedIfNeeded();
    await _dao.updateSession(session.toCompanion());
  }

  @override
  Future<void> deleteSession(String id) async {
    await _seeder.seedIfNeeded();
    await _dao.deleteSession(id);
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
  Stream<List<ReadingSession>> watchSessionsInRange(
    DateTime start,
    DateTime end,
  ) {
    _seeder.seedIfNeeded();
    return _dao
        .watchSessionsInRange(start, end)
        .map((rows) => rows.map((row) => row.toDomain()).toList());
  }
}
