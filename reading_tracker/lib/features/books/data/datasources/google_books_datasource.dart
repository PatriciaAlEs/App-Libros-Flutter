import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/book_search_result.dart';
import 'book_api_datasource.dart';

final googleBooksDatasourceProvider = Provider<GoogleBooksDatasource>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return GoogleBooksDatasource(client);
});

class GoogleBooksDatasource {
  const GoogleBooksDatasource(this._client);

  static const _requestTimeout = Duration(seconds: 8);
  static const _maxAttempts = 2;

  final http.Client _client;

  Future<List<BookSearchResult>> searchBooks(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final uri = Uri.https('www.googleapis.com', '/books/v1/volumes', {
      'q': trimmedQuery,
      'maxResults': '12',
      'printType': 'books',
    });

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await _client.get(uri).timeout(_requestTimeout);
        if (response.statusCode != 200) {
          throw BookSearchException.api(
            'Google Books returned ${response.statusCode}',
          );
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const BookSearchException.invalidResponse(
            'Google Books returned a non-object payload',
          );
        }
        final rawItems = decoded['items'];
        if (rawItems != null && rawItems is! List) {
          throw const BookSearchException.invalidResponse(
            'Google Books returned a non-list items payload',
          );
        }

        return (rawItems as List<dynamic>? ?? const [])
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
        throw BookSearchException.invalidResponse(error);
      } on BookSearchException catch (error, stackTrace) {
        if (attempt == _maxAttempts ||
            error.kind == BookSearchFailureKind.api ||
            error.kind == BookSearchFailureKind.invalidResponse) {
          _logSearchFailure(error, stackTrace);
          rethrow;
        }
      }
    }

    throw const BookSearchException.api('Google Books search failed');
  }

  BookSearchResult _toSearchResult(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'];
    if (volumeInfo is! Map<String, dynamic>) {
      return const BookSearchResult(title: '');
    }

    final identifiers = volumeInfo['industryIdentifiers'];
    final isbn = _isbnFromIdentifiers(identifiers);
    final thumbnail = _imageUrl(volumeInfo['imageLinks']);

    return BookSearchResult(
      title: (volumeInfo['title'] as String?) ?? '',
      author: _firstString(volumeInfo['authors']),
      publisher: volumeInfo['publisher'] as String?,
      coverUrl: thumbnail,
      isbn: isbn,
      externalSource: 'google_books',
      externalId: _normalizedExternalId(json['id'] as String?),
      firstPublishYear: _yearFromDate(volumeInfo['publishedDate']),
      numberOfPages: _positiveInt(volumeInfo['pageCount']),
      categories: _stringList(volumeInfo['categories']),
      description: volumeInfo['description'] as String?,
      language: volumeInfo['language'] as String?,
    );
  }

  String? _isbnFromIdentifiers(Object? value) {
    if (value is! List) return null;
    String? fallback;
    for (final item in value.whereType<Map<String, dynamic>>()) {
      final identifier = item['identifier'] as String?;
      if (identifier == null || identifier.trim().isEmpty) continue;
      final type = item['type'] as String?;
      if (type == 'ISBN_13') return identifier;
      fallback ??= identifier;
    }
    return fallback;
  }

  String? _imageUrl(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final url =
        value['thumbnail'] as String? ?? value['smallThumbnail'] as String?;
    if (url == null || url.isEmpty) return null;
    return url.replaceFirst('http://', 'https://');
  }

  String? _firstString(Object? value) {
    if (value is List) {
      return value
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .firstOrNull;
    }
    return null;
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().where((item) => item.isNotEmpty).toList();
  }

  int? _yearFromDate(Object? value) {
    if (value is! String || value.length < 4) return null;
    return int.tryParse(value.substring(0, 4));
  }

  int? _positiveInt(Object? value) {
    if (value is int && value > 0) return value;
    if (value is num && value > 0) return value.round();
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
    debugPrint('Google Books search failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
