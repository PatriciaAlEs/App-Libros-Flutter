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
      batch.insertAll(booksTable, books);
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
}
