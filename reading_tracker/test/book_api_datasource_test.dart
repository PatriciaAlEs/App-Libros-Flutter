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
