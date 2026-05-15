import 'package:drift/drift.dart';

import 'app_database.dart';
import 'books_table.dart';

part 'book_dao.g.dart';

@DriftAccessor(tables: [BooksTable])
class BookDao extends DatabaseAccessor<AppDatabase> with _$BookDaoMixin {
  BookDao(super.db);

  // ── CREATE ──────────────────────────────────────────────
  Future<void> insertBook(BooksTableCompanion book) =>
      into(booksTable).insert(book);

  // ── READ ────────────────────────────────────────────────
  Future<List<BooksTableData>> getAllBooks() =>
      select(booksTable).get();

  Stream<List<BooksTableData>> watchAllBooks() =>
      select(booksTable).watch();

  Future<BooksTableData?> getBookById(String id) =>
      (select(booksTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<BooksTableData>> getBooksByStatus(String status) =>
      (select(booksTable)..where((t) => t.status.equals(status))).get();

  // ── UPDATE ──────────────────────────────────────────────
  Future<bool> updateBook(BooksTableCompanion book) =>
      update(booksTable).replace(book);

  // ── DELETE ──────────────────────────────────────────────
  Future<int> deleteBook(String id) =>
      (delete(booksTable)..where((t) => t.id.equals(id))).go();
}