import 'dart:async';

import '../../features/books/domain/entities/book.dart';

class AppDatabase {
  AppDatabase() : bookDao = BookDao();

  final BookDao bookDao;

  Future<void> close() => bookDao.close();
}

class BookDao {
  final List<Book> _books = [];
  final StreamController<List<Book>> _controller =
      StreamController<List<Book>>.broadcast();

  Future<void> insertBook(Book book) async {
    _books.add(book);
    _emit();
  }

  Future<List<Book>> getAllBooks() async => List.unmodifiable(_books);

  Stream<List<Book>> watchAllBooks() async* {
    yield List.unmodifiable(_books);
    yield* _controller.stream;
  }

  Future<Book?> getBookById(String id) async {
    for (final book in _books) {
      if (book.id == id) return book;
    }
    return null;
  }

  Future<void> updateBook(Book updatedBook) async {
    final index = _books.indexWhere((book) => book.id == updatedBook.id);
    if (index == -1) return;
    _books[index] = updatedBook;
    _emit();
  }

  Future<void> deleteBook(String id) async {
    _books.removeWhere((book) => book.id == id);
    _emit();
  }

  Future<void> close() => _controller.close();

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_books));
    }
  }
}
