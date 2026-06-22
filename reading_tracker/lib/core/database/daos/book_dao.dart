import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/books_table.dart';

part 'book_dao.g.dart';

@DriftAccessor(tables: [BooksTable])
class BookDao extends DatabaseAccessor<AppDatabase> with _$BookDaoMixin {
  BookDao(super.db);

  Future<void> insertBook(BooksTableCompanion book) {
    return into(booksTable).insert(book);
  }

  Future<void> insertBooks(List<BooksTableCompanion> books) {
    return batch((batch) {
      for (final book in books) {
        batch.insert(booksTable, book, mode: InsertMode.insertOrIgnore);
      }
    });
  }

  Future<void> seedIfEmpty(List<BooksTableCompanion> books) async {
    final existing = await getAllBooks();
    if (existing.isEmpty) {
      await batch((b) => b.insertAll(booksTable, books));
    }
  }

  Future<void> upsertBooks(List<BooksTableCompanion> books) async {
    await batch((b) {
      for (final book in books) {
        b.insert(booksTable, book, mode: InsertMode.insertOrReplace);
      }
    });
  }

  Future<List<BooksTableData>> getAllBooks() {
    return (select(
      booksTable,
    )..orderBy([(table) => OrderingTerm.desc(table.createdAt)])).get();
  }

  Stream<List<BooksTableData>> watchAllBooks() {
    return (select(
      booksTable,
    )..orderBy([(table) => OrderingTerm.desc(table.createdAt)])).watch();
  }

  Future<BooksTableData?> getBookById(String id) {
    return (select(
      booksTable,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<bool> updateBook(BooksTableCompanion book) {
    return update(booksTable).replace(book);
  }

  Future<int> deleteBook(String id) {
    return (delete(booksTable)..where((table) => table.id.equals(id))).go();
  }

  Future<int> deleteAllBooks() {
    return (delete(booksTable)).go();
  }

  Future<int> deleteLegacySeedBooks() {
    return (delete(booksTable)..where(
          (table) => table.id.isIn(const [
            'seed-dune',
            'seed-earthsea',
            'seed-left-hand-darkness',
          ]),
        ))
        .go();
  }
}
