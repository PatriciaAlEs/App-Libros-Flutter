import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/books_table.dart';
import '../../domain/models/book.dart';
import '../../domain/models/book_status.dart';
import '../../domain/repositories/book_repository.dart';

class BookRepositoryImpl implements BookRepository {
  const BookRepositoryImpl(this._dao);

  final BookDao _dao;

  // ── CREATE ──────────────────────────────────────────────
  @override
  Future<void> addBook(Book book) =>
      _dao.insertBook(_toCompanion(book));

  // ── READ ────────────────────────────────────────────────
  @override
  Future<List<Book>> getAllBooks() async {
    final rows = await _dao.getAllBooks();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<Book>> watchBooks() =>
      _dao.watchAllBooks().map((rows) => rows.map(_toDomain).toList());

  @override
  Future<Book?> getBookById(String id) async {
    final row = await _dao.getBookById(id);
    return row != null ? _toDomain(row) : null;
  }

  // ── UPDATE ──────────────────────────────────────────────
  @override
  Future<void> updateBook(Book book) =>
      _dao.updateBook(_toCompanion(book));

  // ── DELETE ──────────────────────────────────────────────
  @override
  Future<void> deleteBook(String id) =>
      _dao.deleteBook(id);

  // ── Mappers ─────────────────────────────────────────────
  Book _toDomain(BooksTableData row) => Book(
        id: row.id,
        title: row.title,
        author: row.author,
        pages: row.pages,
        status: BookStatus.fromString(row.status),
        startDate: row.startDate,
        endDate: row.endDate,
        createdAt: row.createdAt,
      );

  BooksTableCompanion _toCompanion(Book book) => BooksTableCompanion(
        id: Value(book.id),
        title: Value(book.title),
        author: Value(book.author),
        pages: Value(book.pages),
        status: Value(book.status.toValue()),
        startDate: Value(book.startDate),
        endDate: Value(book.endDate),
        createdAt: Value(book.createdAt),
      );
}