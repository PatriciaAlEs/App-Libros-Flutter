import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reading_tracker/features/books/data/datasources/book_api_datasource.dart';
import 'package:reading_tracker/features/books/data/repositories/book_repository_provider.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/books/domain/repositories/book_repository.dart';
import 'package:reading_tracker/features/books/presentation/screens/book_form_screen.dart';
import 'package:reading_tracker/features/books/presentation/screens/books_list_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
  });

  test('book status keeps persisted value and exposes Spanish label', () {
    expect(BookStatus.pending.toValue(), 'pending');
    expect(BookStatus.pending.label, 'Pendiente');
    expect(BookStatus.reading.label, 'Leyendo');
    expect(BookStatus.completed.label, 'Completado');
  });

  testWidgets('shows the books screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(_EmptyBookRepository()),
        ],
        child: const MaterialApp(home: BooksListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('libros en tu colección'), findsOneWidget);
    expect(find.textContaining('Tu biblioteca empieza'), findsOneWidget);
  });

  testWidgets('book form saves the selected initial status', (tester) async {
    final repository = _CapturingBookRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(repository),
          bookApiDatasourceProvider.overrideWithValue(
            BookApiDatasource(
              MockClient((request) async {
                return http.Response(
                  jsonEncode({
                    'docs': [
                      {
                        'title': 'Libro de prueba',
                        'author_name': ['Autora'],
                        'first_publish_year': 2024,
                      },
                    ],
                  }),
                  200,
                );
              }),
            ),
          ),
        ],
        child: const MaterialApp(home: BookFormScreen()),
      ),
    );

    await tester.enterText(_searchField(), 'Libro');
    await tester.tap(find.byKey(const Key('book_search_button')));
    await tester.pumpAndSettle();

    final resultTile = find.byKey(
      const Key('book_result_0_Libro de prueba_Autora_2024'),
    );
    await tester.scrollUntilVisible(
      resultTile,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(resultTile);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<BookStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leyendo').last);
    await tester.pumpAndSettle();
    final saveButton = find.widgetWithText(FilledButton, 'Guardar libro');
    await tester.scrollUntilVisible(
      saveButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(repository.addedBook, isNotNull);
    expect(repository.addedBook!.status, BookStatus.reading);
    expect(repository.addedBook!.startDate, isNotNull);
    expect(
      _dateOnly(repository.addedBook!.startDate!).isAfter(_today()),
      false,
    );
    expect(repository.addedBook!.completedDate, isNull);
  });

  testWidgets('book form auto-searches after debounce with 3 characters', (
    tester,
  ) async {
    var requestCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(_CapturingBookRepository()),
          bookApiDatasourceProvider.overrideWithValue(
            BookApiDatasource(
              MockClient((request) async {
                requestCount++;
                return _searchResponse('Libro automatico');
              }),
            ),
          ),
        ],
        child: const MaterialApp(home: BookFormScreen()),
      ),
    );

    await tester.enterText(_searchField(), 'Li');
    await tester.pump(const Duration(milliseconds: 600));
    expect(requestCount, 0);

    await tester.enterText(_searchField(), 'Lib');
    await tester.pump(const Duration(milliseconds: 499));
    expect(requestCount, 0);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(requestCount, 1);
    final resultTitle = find.byKey(
      const Key('book_result_0_Libro automatico_Autora_2024'),
    );
    await tester.scrollUntilVisible(
      resultTitle,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(resultTitle, findsOneWidget);
  });

  testWidgets('book form keeps manual search button as fallback', (
    tester,
  ) async {
    var requestCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(_CapturingBookRepository()),
          bookApiDatasourceProvider.overrideWithValue(
            BookApiDatasource(
              MockClient((request) async {
                requestCount++;
                return _searchResponse('Libro manual');
              }),
            ),
          ),
        ],
        child: const MaterialApp(home: BookFormScreen()),
      ),
    );

    await tester.enterText(_searchField(), 'Li');
    await tester.tap(find.byKey(const Key('book_search_button')));
    await tester.pumpAndSettle();

    expect(requestCount, 1);
    final resultTitle = find.byKey(
      const Key('book_result_0_Libro manual_Autora_2024'),
    );
    await tester.scrollUntilVisible(
      resultTitle,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(resultTitle, findsOneWidget);
  });
}

Finder _searchField() => find.byType(TextField).first;

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

http.Response _searchResponse(String title) {
  return http.Response(
    jsonEncode({
      'docs': [
        {
          'title': title,
          'author_name': ['Autora'],
          'first_publish_year': 2024,
        },
      ],
    }),
    200,
  );
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

class _CapturingBookRepository implements BookRepository {
  Book? addedBook;

  @override
  Future<void> addBook(Book book) async {
    addedBook = book;
  }

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
