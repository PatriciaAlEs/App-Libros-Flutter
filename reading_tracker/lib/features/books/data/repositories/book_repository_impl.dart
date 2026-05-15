import '../../../../core/database/app_database.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';

class BookRepositoryImpl implements BookRepository {
  const BookRepositoryImpl(this._dao);

  final BookDao _dao;

  @override
  Future<void> addBook(Book book) => _dao.insertBook(book);

  @override
  Future<List<Book>> getAllBooks() => _dao.getAllBooks();

  @override
  Stream<List<Book>> watchBooks() => _dao.watchAllBooks();

  @override
  Future<Book?> getBookById(String id) => _dao.getBookById(id);

  @override
  Future<void> updateBook(Book book) => _dao.updateBook(book);

  @override
  Future<void> deleteBook(String id) => _dao.deleteBook(id);
}
