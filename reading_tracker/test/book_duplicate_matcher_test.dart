import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/entities/book_search_result.dart';
import 'package:reading_tracker/features/books/domain/services/book_duplicate_matcher.dart';

void main() {
  const matcher = BookDuplicateMatcher();

  test('matches books by normalized ISBN', () {
    final existing = Book(
      id: 'book-1',
      title: 'Libro',
      isbn: '978-84-376-0494-7',
      createdAt: DateTime(2026),
    );

    final duplicate = matcher.findDuplicate(
      const BookSearchResult(title: 'Otra edición', isbn: '9788437604947'),
      [existing],
    );

    expect(duplicate?.id, 'book-1');
  });

  test('matches books by provider and external id', () {
    final existing = Book(
      id: 'book-1',
      title: 'Libro',
      externalSource: 'open_library',
      externalId: '/works/OL123W',
      createdAt: DateTime(2026),
    );

    final duplicate = matcher.findDuplicate(
      const BookSearchResult(
        title: 'Libro traducido',
        externalSource: 'open_library',
        externalId: '/works/OL123W',
      ),
      [existing],
    );

    expect(duplicate?.id, 'book-1');
  });

  test('matches books by normalized title and primary author', () {
    final existing = Book(
      id: 'book-1',
      title: 'Cien años de soledad!',
      author: 'Gabriel García Márquez',
      createdAt: DateTime(2026),
    );

    final duplicate = matcher.findDuplicate(
      const BookSearchResult(
        title: '  CIEN ANOS   DE SOLEDAD ',
        author: 'Gabriel Garcia Marquez y otra autora',
      ),
      [existing],
    );

    expect(duplicate?.id, 'book-1');
  });
}
