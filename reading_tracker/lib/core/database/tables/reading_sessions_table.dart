import 'package:drift/drift.dart';

import 'books_table.dart';

class ReadingSessionsTable extends Table {
  @override
  String get tableName => 'reading_sessions';

  TextColumn get id => text()();
  TextColumn get bookId => text().references(BooksTable, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get minutes => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
