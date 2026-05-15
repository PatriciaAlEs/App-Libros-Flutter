import '../models/book.dart';

abstract interface class BookRepository {
  Future<void> addBook(Book book);
  Future<List<Book>> getAllBooks();
  Stream<List<Book>> watchBooks();
  Future<Book?> getBookById(String id);
  Future<void> updateBook(Book book);
  Future<void> deleteBook(String id);
}