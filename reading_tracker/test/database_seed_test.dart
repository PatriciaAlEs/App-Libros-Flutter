import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/core/database/app_database.dart';
import 'package:reading_tracker/core/database/database_seed.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('a clean database remains empty when demo mode is disabled', () async {
    await DatabaseSeeder(database).seedIfNeeded();

    expect(await database.bookDao.getAllBooks(), isEmpty);
  });

  test('legacy demo books are removed without deleting user books', () async {
    final now = DateTime(2026, 6, 22);
    await database.bookDao.insertBooks([
      BooksTableCompanion.insert(
        id: 'seed-dune',
        title: 'Dune',
        createdAt: Value(now),
      ),
      BooksTableCompanion.insert(
        id: 'user-book',
        title: 'Mi libro',
        createdAt: Value(now),
      ),
    ]);

    await DatabaseSeeder(database).seedIfNeeded();

    final books = await database.bookDao.getAllBooks();
    expect(books.map((book) => book.id), ['user-book']);
  });
}
