import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/book_search_result.dart';

final bookApiDatasourceProvider = Provider<BookApiDatasource>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return BookApiDatasource(client);
});

class BookApiDatasource {
  const BookApiDatasource(this._client);

  final http.Client _client;

  Future<List<BookSearchResult>> searchBooks(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final uri = Uri.https('openlibrary.org', '/search.json', {
      'q': trimmedQuery,
      'limit': '12',
      'fields': [
        'title',
        'author_name',
        'publisher',
        'cover_i',
        'isbn',
        'first_publish_year',
        'number_of_pages',
        'number_of_pages_median',
      ].join(','),
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Book search failed (${response.statusCode})');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = payload['docs'] as List<dynamic>? ?? const [];

    return docs
        .whereType<Map<String, dynamic>>()
        .map(_toSearchResult)
        .where((book) => book.title.trim().isNotEmpty)
        .toList();
  }

  BookSearchResult _toSearchResult(Map<String, dynamic> json) {
    final coverId = json['cover_i'];
    final isbns = _stringList(json['isbn']);

    return BookSearchResult(
      title: (json['title'] as String?) ?? '',
      author: _firstValue(json['author_name']),
      publisher: _firstValue(json['publisher']),
      coverUrl: coverId is int
          ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
          : null,
      isbn: isbns.isEmpty ? null : isbns.first,
      firstPublishYear: json['first_publish_year'] as int?,
      numberOfPages:
          _intValue(json['number_of_pages']) ??
          _intValue(json['number_of_pages_median']),
    );
  }

  String? _firstValue(Object? value) {
    final values = _stringList(value);
    return values.isEmpty ? null : values.first;
  }

  List<String> _stringList(Object? value) {
    if (value is List) {
      return value
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  int? _intValue(Object? value) {
    if (value is int && value > 0) return value;
    if (value is num && value > 0) return value.round();
    if (value is List) {
      for (final item in value) {
        final parsed = _intValue(item);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
