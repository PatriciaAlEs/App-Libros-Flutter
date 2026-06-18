import '../entities/book_search_result.dart';

abstract interface class BookSearchRepository {
  Future<List<BookSearchResult>> searchBooks(String query);
}
