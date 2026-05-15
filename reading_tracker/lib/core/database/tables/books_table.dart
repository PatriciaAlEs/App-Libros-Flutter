import 'package:drift/drift.dart';

class BooksTable extends Table {
  @override
  String get tableName => 'books';

  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  IntColumn get totalPages => integer().nullable()();
  IntColumn get currentPage => integer().nullable()();
  RealColumn get rating => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get completedDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
