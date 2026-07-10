import 'package:drift/drift.dart';

import 'connection/database_connection.dart';
import 'daos/book_dao.dart';
import 'daos/reading_session_dao.dart';
import 'daos/sync_metadata_dao.dart';
import 'tables/books_table.dart';
import 'tables/reading_sessions_table.dart';
import 'tables/sync_metadata_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [BooksTable, ReadingSessionsTable, SyncMetadataTable],
  daos: [BookDao, ReadingSessionDao, SyncMetadataDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createAppSettingsTable();
      await _createCoachMemoryTables();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(booksTable, booksTable.genre);
        await migrator.addColumn(booksTable, booksTable.language);
        await migrator.addColumn(booksTable, booksTable.updatedAt);
        await migrator.createTable(readingSessionsTable);
      }
      if (from < 3) {
        await _createAppSettingsTable();
      }
      if (from < 4) {
        await migrator.addColumn(
          readingSessionsTable,
          readingSessionsTable.pagesRead,
        );
        await migrator.addColumn(
          readingSessionsTable,
          readingSessionsTable.updatedAt,
        );
      }
      if (from < 5) {
        await migrator.addColumn(booksTable, booksTable.externalSource);
        await migrator.addColumn(booksTable, booksTable.externalId);
      }
      if (from < 6) {
        await migrator.createTable(syncMetadataTable);
      }
      if (from < 7) {
        await _createCoachMemoryTables();
      }
    },
  );

  Future<void> _createAppSettingsTable() {
    return customStatement('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT NOT NULL PRIMARY KEY,
        int_value INTEGER,
        updated_at INTEGER
      )
    ''');
  }

  Future<void> _createCoachMemoryTables() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS coach_conversations (
        id TEXT NOT NULL PRIMARY KEY,
        title TEXT NOT NULL,
        summary TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        last_message_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS coach_messages (
        id TEXT NOT NULL PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        parent_user_message_id TEXT,
        sequence_number INTEGER NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES coach_conversations(id)
          ON DELETE CASCADE
      )
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_coach_conversations_activity
      ON coach_conversations(last_message_at DESC)
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_coach_messages_conversation_sequence
      ON coach_messages(conversation_id, sequence_number)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_coach_messages_parent
      ON coach_messages(parent_user_message_id)
    ''');
  }
}
