// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_session_dao.dart';

// ignore_for_file: type=lint
mixin _$ReadingSessionDaoMixin on DatabaseAccessor<AppDatabase> {
  $BooksTableTable get booksTable => attachedDatabase.booksTable;
  $ReadingSessionsTableTable get readingSessionsTable =>
      attachedDatabase.readingSessionsTable;
  ReadingSessionDaoManager get managers => ReadingSessionDaoManager(this);
}

class ReadingSessionDaoManager {
  final _$ReadingSessionDaoMixin _db;
  ReadingSessionDaoManager(this._db);
  $$BooksTableTableTableManager get booksTable =>
      $$BooksTableTableTableManager(_db.attachedDatabase, _db.booksTable);
  $$ReadingSessionsTableTableTableManager get readingSessionsTable =>
      $$ReadingSessionsTableTableTableManager(
        _db.attachedDatabase,
        _db.readingSessionsTable,
      );
}
