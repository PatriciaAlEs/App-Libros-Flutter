import '../../../books/domain/entities/book_search_result.dart';

abstract interface class BibliographicSearchService {
  Future<List<BookSearchResult>> search(String query);
}
