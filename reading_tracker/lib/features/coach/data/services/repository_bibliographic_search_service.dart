import '../../../books/domain/entities/book_search_result.dart';
import '../../../books/domain/repositories/book_search_repository.dart';
import '../../domain/services/bibliographic_search_service.dart';

class RepositoryBibliographicSearchService
    implements BibliographicSearchService {
  const RepositoryBibliographicSearchService(this._repository);

  final BookSearchRepository _repository;

  @override
  Future<List<BookSearchResult>> search(String query) =>
      _repository.searchBooks(query);
}
