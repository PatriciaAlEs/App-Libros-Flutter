import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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

  static const _requestTimeout = Duration(seconds: 8);
  static const _maxAttempts = 2;

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

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await _client.get(uri).timeout(_requestTimeout);
        if (response.statusCode != 200) {
          throw BookSearchException.api(
            'Open Library returned ${response.statusCode}',
          );
        }

        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final docs = payload['docs'] as List<dynamic>? ?? const [];

        return docs
            .whereType<Map<String, dynamic>>()
            .map(_toSearchResult)
            .where((book) => book.title.trim().isNotEmpty)
            .toList();
      } on TimeoutException catch (error, stackTrace) {
        if (attempt == _maxAttempts) {
          _logSearchFailure(error, stackTrace);
          throw BookSearchException.timeout(error);
        }
      } on SocketException catch (error, stackTrace) {
        if (attempt == _maxAttempts) {
          _logSearchFailure(error, stackTrace);
          throw BookSearchException.connection(error);
        }
      } on http.ClientException catch (error, stackTrace) {
        if (attempt == _maxAttempts) {
          _logSearchFailure(error, stackTrace);
          throw BookSearchException.connection(error);
        }
      } on FormatException catch (error, stackTrace) {
        _logSearchFailure(error, stackTrace);
        throw BookSearchException.api(error);
      } on BookSearchException catch (error, stackTrace) {
        if (attempt == _maxAttempts ||
            error.kind == BookSearchFailureKind.api) {
          _logSearchFailure(error, stackTrace);
          rethrow;
        }
      }
    }

    throw const BookSearchException.api('Open Library search failed');
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

  void _logSearchFailure(Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    debugPrint('Open Library search failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

enum BookSearchFailureKind { connection, timeout, api }

class BookSearchException implements Exception {
  const BookSearchException(this.kind, this.cause);

  const BookSearchException.connection(Object cause)
    : this(BookSearchFailureKind.connection, cause);

  const BookSearchException.timeout(Object cause)
    : this(BookSearchFailureKind.timeout, cause);

  const BookSearchException.api(Object cause)
    : this(BookSearchFailureKind.api, cause);

  final BookSearchFailureKind kind;
  final Object cause;

  @override
  String toString() => 'BookSearchException($kind, $cause)';
}
