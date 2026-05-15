import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';

// ── Provider del repositorio ─────────────────────────────
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  throw UnimplementedError('bookRepositoryProvider not overridden');
});

// ── Notifier ─────────────────────────────────────────────
class BooksNotifier extends AsyncNotifier<List<Book>> {
  BookRepository get _repo => ref.read(bookRepositoryProvider);

  @override
  Future<List<Book>> build() => _repo.getAllBooks();

  Future<void> loadBooks() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAllBooks());
  }

  Future<void> addBook(Book book) async {
    await _repo.addBook(book);
    await loadBooks();
  }

  Future<void> updateBook(Book book) async {
    await _repo.updateBook(book);
    await loadBooks();
  }

  Future<void> deleteBook(String id) async {
    await _repo.deleteBook(id);
    await loadBooks();
  }
}

// ── Provider expuesto a la UI ────────────────────────────
final booksProvider =
    AsyncNotifierProvider<BooksNotifier, List<Book>>(BooksNotifier.new);