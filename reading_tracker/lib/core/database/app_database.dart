import 'package:drift/drift.dart';

import 'connection/database_connection.dart';
import 'daos/book_dao.dart';
import 'daos/reading_session_dao.dart';
import 'tables/books_table.dart';
import 'tables/reading_sessions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [BooksTable, ReadingSessionsTable],
  daos: [BookDao, ReadingSessionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(booksTable, booksTable.genre);
        await migrator.addColumn(booksTable, booksTable.language);
        await migrator.addColumn(booksTable, booksTable.updatedAt);
        await migrator.createTable(readingSessionsTable);
      }
    },
  );
}
