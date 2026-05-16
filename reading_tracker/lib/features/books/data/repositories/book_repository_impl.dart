import '../../../../core/database/daos/book_dao.dart';
import '../../../../core/database/database_seed.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../mappers/book_mapper.dart';

class BookRepositoryImpl implements BookRepository {
  BookRepositoryImpl(this._dao) : _seeder = DatabaseSeeder(_dao);

  final BookDao _dao;
  final DatabaseSeeder _seeder;

  @override
  Future<void> addBook(Book book) async {
    await _seeder.seedIfNeeded();
    return _dao.insertBook(book.toCompanion());
  }

  @override
  Future<List<Book>> getAllBooks() async {
    await _seeder.seedIfNeeded();
    final rows = await _dao.getAllBooks();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Stream<List<Book>> watchBooks() {
    _seeder.seedIfNeeded();
    return _dao.watchAllBooks().map(
      (rows) => rows.map((row) => row.toDomain()).toList(),
    );
  }

  @override
  Future<Book?> getBookById(String id) async {
    await _seeder.seedIfNeeded();
    final row = await _dao.getBookById(id);
    return row?.toDomain();
  }

  @override
  Future<void> updateBook(Book book) async {
    await _seeder.seedIfNeeded();
    await _dao.updateBook(book.toCompanion());
  }

  @override
  Future<void> deleteBook(String id) async {
    await _seeder.seedIfNeeded();
    await _dao.deleteBook(id);
  }
}
