import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reading_tracker/features/books/data/datasources/book_api_datasource.dart';

void main() {
  test('searchBooks retries a transient client failure', () async {
    var attempts = 0;
    final datasource = BookApiDatasource(
      MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          throw http.ClientException('network reset', request.url);
        }

        return _searchResponse('Libro recuperado');
      }),
    );

    final results = await datasource.searchBooks('Libro');

    expect(attempts, 2);
    expect(results.single.title, 'Libro recuperado');
  });

  test(
    'searchBooks maps persistent client failures to connection error',
    () async {
      final datasource = BookApiDatasource(
        MockClient((request) async {
          throw http.ClientException('offline', request.url);
        }),
      );

      expect(
        () => datasource.searchBooks('Libro'),
        throwsA(
          isA<BookSearchException>().having(
            (error) => error.kind,
            'kind',
            BookSearchFailureKind.connection,
          ),
        ),
      );
    },
  );

  test('searchBooks maps timeouts to timeout error', () async {
    final datasource = BookApiDatasource(
      MockClient((request) async {
        throw TimeoutException('slow');
      }),
    );

    expect(
      () => datasource.searchBooks('Libro'),
      throwsA(
        isA<BookSearchException>().having(
          (error) => error.kind,
          'kind',
          BookSearchFailureKind.timeout,
        ),
      ),
    );
  });

  test('searchBooks maps non-200 responses to api error', () async {
    final datasource = BookApiDatasource(
      MockClient((request) async => http.Response('Service unavailable', 503)),
    );

    expect(
      () => datasource.searchBooks('Libro'),
      throwsA(
        isA<BookSearchException>().having(
          (error) => error.kind,
          'kind',
          BookSearchFailureKind.api,
        ),
      ),
    );
  });

  test('searchBooks maps invalid payloads to invalid response error', () async {
    final datasource = BookApiDatasource(
      MockClient((request) async => http.Response('[]', 200)),
    );

    expect(
      () => datasource.searchBooks('Libro'),
      throwsA(
        isA<BookSearchException>().having(
          (error) => error.kind,
          'kind',
          BookSearchFailureKind.invalidResponse,
        ),
      ),
    );
  });

  test('searchBooks keeps Open Library key as external id', () async {
    final datasource = BookApiDatasource(
      MockClient(
        (request) async => http.Response(
          jsonEncode({
            'docs': [
              {
                'title': 'Dune',
                'key': '/works/OL893415W',
                'subject': ['Science Fiction'],
                'language': ['eng'],
                'first_sentence': ['A desert world.'],
              },
            ],
          }),
          200,
        ),
      ),
    );

    final results = await datasource.searchBooks('Dune');

    expect(results.single.externalSource, 'open_library');
    expect(results.single.externalId, 'WORKSOL893415W');
    expect(results.single.categories, ['Science Fiction']);
    expect(results.single.language, 'eng');
    expect(results.single.description, 'A desert world.');
  });
}

http.Response _searchResponse(String title) {
  return http.Response(
    jsonEncode({
      'docs': [
        {'title': title},
      ],
    }),
    200,
  );
}
