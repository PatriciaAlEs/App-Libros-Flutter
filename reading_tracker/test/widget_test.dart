import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reading_tracker/app.dart';
import 'package:reading_tracker/features/books/data/repositories/book_repository_provider.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/repositories/book_repository.dart';

void main() {
  testWidgets('shows the books screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(_EmptyBookRepository()),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Books'), findsOneWidget);
    expect(find.text('No books yet.'), findsOneWidget);
  });
}

class _EmptyBookRepository implements BookRepository {
  @override
  Future<void> addBook(Book book) async {}

  @override
  Future<void> deleteBook(String id) async {}

  @override
  Future<List<Book>> getAllBooks() async => const [];

  @override
  Future<Book?> getBookById(String id) async => null;

  @override
  Future<void> updateBook(Book book) async {}

  @override
  Stream<List<Book>> watchBooks() => Stream.value(const []);
}
