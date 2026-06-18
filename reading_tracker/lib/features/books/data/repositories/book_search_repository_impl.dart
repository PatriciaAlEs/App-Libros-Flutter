import 'package:flutter/foundation.dart';

import '../../domain/entities/book_search_result.dart';
import '../../domain/repositories/book_search_repository.dart';
import '../datasources/book_api_datasource.dart';
import '../datasources/google_books_datasource.dart';

class BookSearchRepositoryImpl implements BookSearchRepository {
  const BookSearchRepositoryImpl({
    required BookApiDatasource openLibraryDatasource,
    required GoogleBooksDatasource googleBooksDatasource,
  }) : _openLibraryDatasource = openLibraryDatasource,
       _googleBooksDatasource = googleBooksDatasource;

  final BookApiDatasource _openLibraryDatasource;
  final GoogleBooksDatasource _googleBooksDatasource;

  @override
  Future<List<BookSearchResult>> searchBooks(String query) async {
    try {
      _log('Searching primary provider: Open Library');
      final openLibraryResults = await _openLibraryDatasource.searchBooks(
        query,
      );
      _log('Open Library returned ${openLibraryResults.length} results');
      if (openLibraryResults.isNotEmpty) {
        _log('Using Open Library results');
        return openLibraryResults;
      }
      _log('Fallback activated: Open Library returned no results');
    } on BookSearchException catch (error) {
      _log('Fallback activated: Open Library failed with ${error.kind}');
    }

    _log('Searching secondary provider: Google Books');
    final googleBooksResults = await _googleBooksDatasource.searchBooks(query);
    _log('Google Books returned ${googleBooksResults.length} results');
    return googleBooksResults;
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('BookSearchRepository: $message');
  }
}
