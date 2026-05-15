import 'package:drift/drift.dart';

import 'connection/database_connection.dart';
import 'daos/book_dao.dart';
import 'tables/books_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [BooksTable], daos: [BookDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) => migrator.createAll(),
      );
}
