import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reading_tracker/features/books/data/datasources/google_books_datasource.dart';

void main() {
  test('searchBooks maps Google Books volumes to search results', () async {
    final datasource = GoogleBooksDatasource(
      MockClient(
        (request) async => http.Response(
          jsonEncode({
            'items': [
              {
                'id': 'abc-123',
                'volumeInfo': {
                  'title': 'A Court of Thorns and Roses',
                  'authors': ['Sarah J. Maas'],
                  'publisher': 'Bloomsbury',
                  'publishedDate': '2015-05-05',
                  'pageCount': 419,
                  'industryIdentifiers': [
                    {'type': 'ISBN_10', 'identifier': '1619634449'},
                    {'type': 'ISBN_13', 'identifier': '9781619634442'},
                  ],
                  'imageLinks': {
                    'thumbnail': 'http://books.google.com/cover.jpg',
                  },
                },
              },
            ],
          }),
          200,
        ),
      ),
    );

    final results = await datasource.searchBooks('acotar');

    expect(results.single.title, 'A Court of Thorns and Roses');
    expect(results.single.author, 'Sarah J. Maas');
    expect(results.single.publisher, 'Bloomsbury');
    expect(results.single.isbn, '9781619634442');
    expect(results.single.coverUrl, 'https://books.google.com/cover.jpg');
    expect(results.single.externalSource, 'google_books');
    expect(results.single.externalId, 'ABC123');
    expect(results.single.firstPublishYear, 2015);
    expect(results.single.numberOfPages, 419);
  });
}
