import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reading_tracker/features/books/data/datasources/book_api_datasource.dart';
import 'package:reading_tracker/features/books/data/datasources/google_books_datasource.dart';
import 'package:reading_tracker/features/books/data/repositories/book_search_repository_impl.dart';

void main() {
  test('uses Open Library results without querying Google Books', () async {
    var googleRequests = 0;
    final repository = BookSearchRepositoryImpl(
      openLibraryDatasource: BookApiDatasource(
        MockClient((request) async => _openLibraryResponse('Open result')),
      ),
      googleBooksDatasource: GoogleBooksDatasource(
        MockClient((request) async {
          googleRequests++;
          return _googleBooksResponse('Google result');
        }),
      ),
    );

    final results = await repository.searchBooks('book');

    expect(results.single.title, 'Open result');
    expect(results.single.externalSource, 'open_library');
    expect(googleRequests, 0);
  });

  test('falls back to Google Books when Open Library has no results', () async {
    final repository = BookSearchRepositoryImpl(
      openLibraryDatasource: BookApiDatasource(
        MockClient(
          (request) async => http.Response(jsonEncode({'docs': []}), 200),
        ),
      ),
      googleBooksDatasource: GoogleBooksDatasource(
        MockClient((request) async => _googleBooksResponse('Google result')),
      ),
    );

    final results = await repository.searchBooks('book');

    expect(results.single.title, 'Google result');
    expect(results.single.externalSource, 'google_books');
  });

  test('falls back to Google Books when Open Library fails', () async {
    final repository = BookSearchRepositoryImpl(
      openLibraryDatasource: BookApiDatasource(
        MockClient((request) async => http.Response('Unavailable', 503)),
      ),
      googleBooksDatasource: GoogleBooksDatasource(
        MockClient((request) async => _googleBooksResponse('Google result')),
      ),
    );

    final results = await repository.searchBooks('book');

    expect(results.single.title, 'Google result');
    expect(results.single.externalSource, 'google_books');
  });

  test(
    'keeps no-results outcome when primary is empty and fallback fails',
    () async {
      final repository = BookSearchRepositoryImpl(
        openLibraryDatasource: BookApiDatasource(
          MockClient(
            (request) async => http.Response(jsonEncode({'docs': []}), 200),
          ),
        ),
        googleBooksDatasource: GoogleBooksDatasource(
          MockClient((request) async => http.Response('Unavailable', 503)),
        ),
      );

      final results = await repository.searchBooks('dsladhflhlhf');

      expect(results, isEmpty);
    },
  );

  test('throws when every provider fails', () async {
    final repository = BookSearchRepositoryImpl(
      openLibraryDatasource: BookApiDatasource(
        MockClient((request) async => http.Response('Unavailable', 503)),
      ),
      googleBooksDatasource: GoogleBooksDatasource(
        MockClient((request) async => http.Response('Unavailable', 503)),
      ),
    );

    expect(
      () => repository.searchBooks('book'),
      throwsA(isA<BookSearchException>()),
    );
  });
}

http.Response _openLibraryResponse(String title) {
  return http.Response(
    jsonEncode({
      'docs': [
        {'title': title, 'key': '/works/OL1W'},
      ],
    }),
    200,
  );
}

http.Response _googleBooksResponse(String title) {
  return http.Response(
    jsonEncode({
      'items': [
        {
          'id': 'google-1',
          'volumeInfo': {
            'title': title,
            'authors': ['Autora'],
          },
        },
      ],
    }),
    200,
  );
}
