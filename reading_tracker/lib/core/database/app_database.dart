import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'book_dao.dart';
import 'books_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [BooksTable], daos: [BookDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Migraciones futuras aquí
        },
      );

  late final BookDao bookDao = BookDao(this);
}

// ── Conexión SQLite ──────────────────────────────────────
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'reading_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}