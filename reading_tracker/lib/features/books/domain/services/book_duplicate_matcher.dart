import '../entities/book.dart';
import '../entities/book_search_result.dart';

class BookDuplicateMatcher {
  const BookDuplicateMatcher();

  Book? findDuplicate(BookSearchResult candidate, List<Book> existingBooks) {
    final candidateFingerprint = BookFingerprint.fromSearchResult(candidate);

    for (final book in existingBooks) {
      final existingFingerprint = BookFingerprint.fromBook(book);
      if (candidateFingerprint.matches(existingFingerprint)) {
        return book;
      }
    }

    return null;
  }
}

class BookFingerprint {
  const BookFingerprint({
    required this.title,
    required this.author,
    required this.isbn,
    required this.externalSource,
    required this.externalId,
  });

  factory BookFingerprint.fromSearchResult(BookSearchResult book) {
    return BookFingerprint(
      title: normalizeBookText(book.title),
      author: normalizePrimaryAuthor(book.author),
      isbn: normalizeBookIdentifier(book.isbn),
      externalSource: normalizeBookText(book.externalSource ?? ''),
      externalId: normalizeBookIdentifier(book.externalId),
    );
  }

  factory BookFingerprint.fromBook(Book book) {
    return BookFingerprint(
      title: normalizeBookText(book.title),
      author: normalizePrimaryAuthor(book.author),
      isbn: normalizeBookIdentifier(book.isbn),
      externalSource: normalizeBookText(book.externalSource ?? ''),
      externalId: normalizeBookIdentifier(book.externalId),
    );
  }

  final String title;
  final String author;
  final String isbn;
  final String externalSource;
  final String externalId;

  bool matches(BookFingerprint other) {
    if (isbn.isNotEmpty && other.isbn.isNotEmpty && isbn == other.isbn) {
      return true;
    }

    if (externalSource.isNotEmpty &&
        externalId.isNotEmpty &&
        externalSource == other.externalSource &&
        externalId == other.externalId) {
      return true;
    }

    return title.isNotEmpty &&
        author.isNotEmpty &&
        title == other.title &&
        author == other.author;
  }
}

String normalizeBookIdentifier(String? value) {
  return (value ?? '').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

String normalizePrimaryAuthor(String? value) {
  final normalized = normalizeBookText(value ?? '');
  if (normalized.isEmpty) return '';
  return normalized.split(RegExp(r'\s+(?:and|y|e)\s+|,|&|;')).first.trim();
}

String normalizeBookText(String value) {
  final lower = value.toLowerCase().trim();
  final withoutAccents = lower.split('').map(_foldAccent).join();
  return withoutAccents
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'_'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _foldAccent(String char) {
  return switch (char) {
    'á' ||
    'à' ||
    'ä' ||
    'â' ||
    'ã' ||
    'å' ||
    'Á' ||
    'À' ||
    'Ä' ||
    'Â' ||
    'Ã' ||
    'Å' ||
    'Ã¡' ||
    'Ã ' ||
    'Ã¤' ||
    'Ã¢' ||
    'Ã£' => 'a',
    'é' ||
    'è' ||
    'ë' ||
    'ê' ||
    'É' ||
    'È' ||
    'Ë' ||
    'Ê' ||
    'Ã©' ||
    'Ã¨' ||
    'Ã«' ||
    'Ãª' => 'e',
    'í' ||
    'ì' ||
    'ï' ||
    'î' ||
    'Í' ||
    'Ì' ||
    'Ï' ||
    'Î' ||
    'Ã­' ||
    'Ã¬' ||
    'Ã¯' ||
    'Ã®' => 'i',
    'ó' ||
    'ò' ||
    'ö' ||
    'ô' ||
    'õ' ||
    'Ó' ||
    'Ò' ||
    'Ö' ||
    'Ô' ||
    'Õ' ||
    'Ã³' ||
    'Ã²' ||
    'Ã¶' ||
    'Ã´' ||
    'Ãµ' => 'o',
    'ú' ||
    'ù' ||
    'ü' ||
    'û' ||
    'Ú' ||
    'Ù' ||
    'Ü' ||
    'Û' ||
    'Ãº' ||
    'Ã¹' ||
    'Ã¼' ||
    'Ã»' => 'u',
    'ñ' || 'Ñ' || 'Ã±' => 'n',
    'ç' || 'Ç' || 'Ã§' => 'c',
    _ => char,
  };
}
