import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:reading_tracker/app.dart';
import 'package:reading_tracker/features/books/data/datasources/book_api_datasource.dart';
import 'package:reading_tracker/features/books/data/repositories/book_repository_provider.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/books/domain/repositories/book_repository.dart';
import 'package:reading_tracker/features/books/presentation/screens/book_form_screen.dart';

void main() {
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
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mis libros'), findsOneWidget);
    expect(
      find.text(
        'Todavía no tienes libros. Añade tu primer libro con el botón +.',
      ),
      findsOneWidget,
    );
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

    await tester.enterText(find.byType(TextField), 'Libro');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Libro de prueba'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pendiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leyendo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar libro'));
    await tester.pumpAndSettle();

    expect(repository.addedBook, isNotNull);
    expect(repository.addedBook!.status, BookStatus.reading);
    expect(repository.addedBook!.startDate, isNotNull);
    expect(repository.addedBook!.completedDate, isNull);
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
