import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/observability/readpp_sentry.dart';
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
        'key',
        'cover_i',
        'isbn',
        'first_publish_year',
        'number_of_pages',
        'number_of_pages_median',
      ].join(','),
    });
    final stopwatch = Stopwatch()..start();
    int? lastStatusCode;

    unawaited(
      ReadPpSentry.addBookSearchBreadcrumb(
        event: 'search_started',
        provider: 'open_library',
        query: trimmedQuery,
      ),
    );

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await _client.get(uri).timeout(_requestTimeout);
        lastStatusCode = response.statusCode;
        if (response.statusCode != 200) {
          throw BookSearchException.api(
            'Open Library returned ${response.statusCode}',
          );
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const BookSearchException.invalidResponse(
            'Open Library returned a non-object payload',
          );
        }
        final payload = decoded;
        final rawDocs = payload['docs'];
        if (rawDocs != null && rawDocs is! List) {
          throw const BookSearchException.invalidResponse(
            'Open Library returned a non-list docs payload',
          );
        }
        final docs = rawDocs as List<dynamic>? ?? const [];

        final results = docs
            .whereType<Map<String, dynamic>>()
            .map(_toSearchResult)
            .where((book) => book.title.trim().isNotEmpty)
            .toList();
        unawaited(
          ReadPpSentry.addBookSearchBreadcrumb(
            event: 'search_completed',
            provider: 'open_library',
            query: trimmedQuery,
            duration: stopwatch.elapsed,
            resultCount: results.length,
            statusCode: lastStatusCode,
          ),
        );
        return results;
      } on TimeoutException catch (error, stackTrace) {
        if (attempt == _maxAttempts) {
          _logSearchFailure(error, stackTrace);
          unawaited(
            _reportSearchFailure(
              error,
              stackTrace,
              query: trimmedQuery,
              duration: stopwatch.elapsed,
              failureKind: BookSearchFailureKind.timeout.name,
              statusCode: lastStatusCode,
            ),
          );
          throw BookSearchException.timeout(error);
        }
      } on SocketException catch (error, stackTrace) {
        if (attempt == _maxAttempts) {
          _logSearchFailure(error, stackTrace);
          unawaited(
            _reportSearchFailure(
              error,
              stackTrace,
              query: trimmedQuery,
              duration: stopwatch.elapsed,
              failureKind: BookSearchFailureKind.connection.name,
              statusCode: lastStatusCode,
            ),
          );
          throw BookSearchException.connection(error);
        }
      } on http.ClientException catch (error, stackTrace) {
        if (attempt == _maxAttempts) {
          _logSearchFailure(error, stackTrace);
          unawaited(
            _reportSearchFailure(
              error,
              stackTrace,
              query: trimmedQuery,
              duration: stopwatch.elapsed,
              failureKind: BookSearchFailureKind.connection.name,
              statusCode: lastStatusCode,
            ),
          );
          throw BookSearchException.connection(error);
        }
      } on FormatException catch (error, stackTrace) {
        _logSearchFailure(error, stackTrace);
        unawaited(
          _reportSearchFailure(
            error,
            stackTrace,
            query: trimmedQuery,
            duration: stopwatch.elapsed,
            failureKind: BookSearchFailureKind.invalidResponse.name,
            statusCode: lastStatusCode,
          ),
        );
        throw BookSearchException.invalidResponse(error);
      } on BookSearchException catch (error, stackTrace) {
        if (attempt == _maxAttempts ||
            error.kind == BookSearchFailureKind.api ||
            error.kind == BookSearchFailureKind.invalidResponse) {
          _logSearchFailure(error, stackTrace);
          unawaited(
            _reportSearchFailure(
              error,
              stackTrace,
              query: trimmedQuery,
              duration: stopwatch.elapsed,
              failureKind: error.kind.name,
              statusCode: lastStatusCode,
            ),
          );
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
      externalSource: 'open_library',
      externalId: _normalizedExternalId(json['key'] as String?),
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

  String? _normalizedExternalId(String? value) {
    final normalized = (value ?? '').toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    return normalized.isEmpty ? null : normalized;
  }

  void _logSearchFailure(Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    debugPrint('Open Library search failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  Future<void> _reportSearchFailure(
    Object error,
    StackTrace stackTrace, {
    required String query,
    required Duration duration,
    required String failureKind,
    int? statusCode,
  }) async {
    await ReadPpSentry.addBookSearchBreadcrumb(
      event: 'search_failed',
      provider: 'open_library',
      query: query,
      duration: duration,
      failureKind: failureKind,
      statusCode: statusCode,
    );
    await ReadPpSentry.captureOpenLibraryException(
      exception: error,
      stackTrace: stackTrace,
      query: query,
      duration: duration,
      failureKind: failureKind,
      statusCode: statusCode,
    );
  }
}

enum BookSearchFailureKind { connection, timeout, api, invalidResponse }

class BookSearchException implements Exception {
  const BookSearchException(this.kind, this.cause);

  const BookSearchException.connection(Object cause)
    : this(BookSearchFailureKind.connection, cause);

  const BookSearchException.timeout(Object cause)
    : this(BookSearchFailureKind.timeout, cause);

  const BookSearchException.api(Object cause)
    : this(BookSearchFailureKind.api, cause);

  const BookSearchException.invalidResponse(Object cause)
    : this(BookSearchFailureKind.invalidResponse, cause);

  final BookSearchFailureKind kind;
  final Object cause;

  @override
  String toString() => 'BookSearchException($kind, $cause)';
}
