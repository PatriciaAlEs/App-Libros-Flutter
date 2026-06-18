import '../../domain/entities/book_search_result.dart';
import '../../domain/repositories/book_search_repository.dart';
import '../datasources/book_api_datasource.dart';

class BookSearchRepositoryImpl implements BookSearchRepository {
  const BookSearchRepositoryImpl(this._primaryDatasource);

  final BookApiDatasource _primaryDatasource;

  @override
  Future<List<BookSearchResult>> searchBooks(String query) {
    return _primaryDatasource.searchBooks(query);
  }
}
