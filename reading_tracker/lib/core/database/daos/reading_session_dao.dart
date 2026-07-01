import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/reading_sessions_table.dart';

part 'reading_session_dao.g.dart';

@DriftAccessor(tables: [ReadingSessionsTable])
class ReadingSessionDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingSessionDaoMixin {
  ReadingSessionDao(super.db);

  Future<void> insertSession(ReadingSessionsTableCompanion session) {
    return into(readingSessionsTable).insert(session);
  }

  Future<void> insertSessions(List<ReadingSessionsTableCompanion> sessions) {
    return batch((batch) {
      for (final session in sessions) {
        batch.insert(
          readingSessionsTable,
          session,
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<bool> updateSession(ReadingSessionsTableCompanion session) {
    return update(readingSessionsTable).replace(session);
  }

  Future<int> deleteSession(String id) {
    return (delete(
      readingSessionsTable,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<ReadingSessionsTableData?> getSessionById(String id) {
    return (select(
      readingSessionsTable,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<int> deleteLegacySeedSessions() {
    return (delete(readingSessionsTable)..where(
          (table) =>
              table.id.like('seed-session-%') &
              table.note.equals('Sesion de prueba'),
        ))
        .go();
  }

  Future<List<ReadingSessionsTableData>> getSessionsForDay(DateTime day) {
    final range = _dayRange(day);
    return _sessionsInRange(range.start, range.end).get();
  }

  Future<List<ReadingSessionsTableData>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) {
    return _sessionsInRange(start, end).get();
  }

  Future<List<ReadingSessionsTableData>> getSessionsForBook(String bookId) {
    return (select(readingSessionsTable)
          ..where((table) => table.bookId.equals(bookId))
          ..orderBy([
            (table) => OrderingTerm.desc(table.date),
            (table) => OrderingTerm.desc(table.createdAt),
          ]))
        .get();
  }

  Stream<List<ReadingSessionsTableData>> watchSessionsInRange(
    DateTime start,
    DateTime end,
  ) {
    return _sessionsInRange(start, end).watch();
  }

  SimpleSelectStatement<$ReadingSessionsTableTable, ReadingSessionsTableData>
  _sessionsInRange(DateTime start, DateTime end) {
    return select(readingSessionsTable)
      ..where(
        (table) =>
            table.date.isBiggerOrEqualValue(_dateOnly(start)) &
            table.date.isSmallerThanValue(_dateOnly(end)),
      )
      ..orderBy([
        (table) => OrderingTerm.asc(table.date),
        (table) => OrderingTerm.desc(table.createdAt),
      ]);
  }

  ({DateTime start, DateTime end}) _dayRange(DateTime day) {
    final start = _dateOnly(day);
    return (start: start, end: start.add(const Duration(days: 1)));
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
