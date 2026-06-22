import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reading_tracker/core/design_system/design_system.dart';
import 'package:reading_tracker/core/theme/app_theme.dart';
import 'package:reading_tracker/features/books/data/datasources/book_api_datasource.dart';
import 'package:reading_tracker/features/books/data/datasources/google_books_datasource.dart';
import 'package:reading_tracker/features/books/data/repositories/book_repository_provider.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/books/domain/repositories/book_repository.dart';
import 'package:reading_tracker/features/books/presentation/screens/book_form_screen.dart';
import 'package:reading_tracker/features/books/presentation/screens/books_list_screen.dart';
import 'package:reading_tracker/features/home/presentation/screens/home_screen.dart';
import 'package:reading_tracker/features/navigation/presentation/screens/main_navigation_screen.dart';
import 'package:reading_tracker/features/reading_sessions/data/repositories/reading_session_repository_provider.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';
import 'package:reading_tracker/features/reading_sessions/domain/repositories/reading_session_repository.dart';
import 'package:reading_tracker/features/stats/data/repositories/statistics_repository_provider.dart';
import 'package:reading_tracker/features/stats/domain/entities/statistics_summary.dart';
import 'package:reading_tracker/features/stats/domain/repositories/statistics_repository.dart';

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

  testWidgets('editorial titles keep the display font family', (tester) async {
    final theme = AppTheme.light();

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Column(
            children: [
              const SectionHeader(title: 'Objetivo anual'),
              Text('Texto funcional', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );

    final sectionTitle = tester.widget<Text>(find.text('Objetivo anual'));
    final bodyText = tester.widget<Text>(find.text('Texto funcional'));
    expect(
      sectionTitle.style?.fontFamily,
      theme.textTheme.headlineSmall?.fontFamily,
    );
    expect(bodyText.style?.fontFamily, theme.textTheme.bodyMedium?.fontFamily);
    expect(sectionTitle.style?.fontFamily, isNot(bodyText.style?.fontFamily));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(_EmptyBookRepository()),
        ],
        child: MaterialApp(theme: theme, home: const BookFormScreen()),
      ),
    );

    final addBookTitle = tester.widget<Text>(find.text('Añadir libro').first);
    expect(
      addBookTitle.style?.fontFamily,
      theme.textTheme.headlineSmall?.fontFamily,
    );
  });

  testWidgets('shared navbar exposes every main destination', (tester) async {
    int? selectedIndex;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ReadPpBottomNavigation(
            selectedIndex: null,
            onSelect: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Progreso'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);

    await tester.tap(find.text('Biblioteca'));
    expect(selectedIndex, 1);
  });

  testWidgets('main shell keeps navbar while a child route is open', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(_EmptyBookRepository()),
        ],
        child: const MaterialApp(home: MainNavigationScreen(initialIndex: 1)),
      ),
    );
    await tester.pumpAndSettle();

    final booksContext = tester.element(find.byType(BooksListScreen));
    Navigator.of(booksContext).pushNamed('/book/add');
    await tester.pumpAndSettle();

    expect(find.text('Añadir libro'), findsWidgets);
    expect(find.byType(ReadPpBottomNavigation), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(BooksListScreen), findsOneWidget);
    expect(find.byType(ReadPpBottomNavigation), findsOneWidget);
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
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
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

  testWidgets('book form can save a manual book when search has no results', (
    tester,
  ) async {
    final repository = _CapturingBookRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(repository),
          bookApiDatasourceProvider.overrideWithValue(
            BookApiDatasource(
              MockClient((request) async {
                return http.Response(jsonEncode({'docs': []}), 200);
              }),
            ),
          ),
          googleBooksDatasourceProvider.overrideWithValue(
            GoogleBooksDatasource(
              MockClient((request) async => http.Response('Unavailable', 503)),
            ),
          ),
        ],
        child: const MaterialApp(home: BookFormScreen()),
      ),
    );

    await tester.enterText(_searchField(), 'Libro sin portada');
    await tester.tap(find.byKey(const Key('book_search_button')));
    await tester.pumpAndSettle();
    final manualButton = find.widgetWithText(
      OutlinedButton,
      'Añadir manualmente',
    );
    await tester.scrollUntilVisible(
      manualButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('No hemos encontrado resultados para tu búsqueda.'),
      findsOneWidget,
    );
    expect(find.textContaining('No hemos podido conectar'), findsNothing);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(manualButton);
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(FilledButton, 'Guardar libro');
    await tester.scrollUntilVisible(
      saveButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(repository.addedBook, isNotNull);
    expect(repository.addedBook!.title, 'Libro sin portada');
    expect(repository.addedBook!.coverUrl, isNull);
  });

  testWidgets('book form distinguishes provider errors from no results', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(_CapturingBookRepository()),
          bookApiDatasourceProvider.overrideWithValue(
            BookApiDatasource(
              MockClient((request) async => http.Response('Unavailable', 503)),
            ),
          ),
          googleBooksDatasourceProvider.overrideWithValue(
            GoogleBooksDatasource(
              MockClient((request) async => http.Response('Unavailable', 503)),
            ),
          ),
        ],
        child: const MaterialApp(home: BookFormScreen()),
      ),
    );

    await tester.enterText(_searchField(), 'dsladhflhlhf');
    await tester.tap(find.byKey(const Key('book_search_button')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No hemos podido conectar con Open Library.'),
      findsOneWidget,
    );
    expect(find.text('Añadir manualmente'), findsOneWidget);
    expect(
      find.text('No hemos encontrado resultados para tu búsqueda.'),
      findsNothing,
    );
  });

  testWidgets('home swipes between multiple active readings', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'reader_profile_current_reading_id': 'book-1',
    });
    final books = [
      _book(
        id: 'book-1',
        title: 'Lectura principal',
        currentPage: 40,
        updatedAt: DateTime(2026, 6, 16),
      ),
      _book(
        id: 'book-2',
        title: 'Segunda lectura',
        currentPage: 90,
        updatedAt: DateTime(2026, 6, 15),
      ),
      _book(
        id: 'book-3',
        title: 'Tercera lectura',
        currentPage: 25,
        updatedAt: DateTime(2026, 6, 14),
      ),
      _book(
        id: 'book-4',
        title: 'Cuarta lectura',
        currentPage: 120,
        updatedAt: DateTime(2026, 6, 13),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(_BooksRepository(books)),
          statisticsRepositoryProvider.overrideWithValue(
            const _EmptyStatisticsRepository(),
          ),
          readingSessionRepositoryProvider.overrideWithValue(
            const _EmptyReadingSessionRepository(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.text('Lectura principal'), findsWidgets);
    expect(find.text('LECTURA PRINCIPAL'), findsOneWidget);
    expect(find.text('160 restantes'), findsOneWidget);
    expect(
      _semanticsWithLabel('Lectura principal: Lectura principal'),
      findsOneWidget,
    );

    final carousel = find.byKey(const Key('current_reading_cards_page_view'));

    await tester.drag(carousel, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Registrar avance'), findsNothing);
    expect(find.text('2 / 4'), findsOneWidget);
    expect(find.text('Segunda lectura'), findsWidgets);
    expect(find.text('LECTURA EN CURSO'), findsOneWidget);
    expect(find.text('110 restantes'), findsOneWidget);
    expect(
      _semanticsWithLabel('Lectura en curso: Segunda lectura'),
      findsOneWidget,
    );

    await tester.drag(carousel, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('3 / 4'), findsOneWidget);
    expect(find.text('Tercera lectura'), findsWidgets);

    await tester.drag(carousel, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('4 / 4'), findsOneWidget);
    expect(find.text('Cuarta lectura'), findsWidgets);
  });

  testWidgets('book form blocks duplicate books by ISBN', (tester) async {
    final repository = _CapturingBookRepository(
      existingBooks: [
        Book(
          id: 'existing-book',
          title: 'Libro existente',
          author: 'Autora',
          isbn: '978-84-376-0494-7',
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );

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
                        'title': 'Otra edición',
                        'author_name': ['Autora'],
                        'isbn': ['9788437604947'],
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

    await tester.enterText(_searchField(), 'Libro duplicado');
    await tester.tap(find.byKey(const Key('book_search_button')));
    await tester.pumpAndSettle();

    final resultTile = find.byKey(
      const Key('book_result_0_Otra edición_Autora_2024'),
    );
    await tester.scrollUntilVisible(
      resultTile,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(resultTile);
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(FilledButton, 'Guardar libro');
    await tester.scrollUntilVisible(
      saveButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(repository.addedBook, isNull);
    expect(find.text('Este libro ya está en tu biblioteca'), findsOneWidget);
  });

  testWidgets(
    'book form blocks duplicate books by normalized title and author',
    (tester) async {
      final repository = _CapturingBookRepository(
        existingBooks: [
          Book(
            id: 'existing-book',
            title: 'Cien años de soledad',
            author: 'Gabriel García Márquez',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );

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
                          'title': 'Cien anos de soledad',
                          'author_name': ['Gabriel Garcia Marquez'],
                          'first_publish_year': 1967,
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

      await tester.enterText(_searchField(), 'Cien años');
      await tester.tap(find.byKey(const Key('book_search_button')));
      await tester.pumpAndSettle();

      final resultTile = find.byKey(
        const Key(
          'book_result_0_Cien anos de soledad_Gabriel Garcia Marquez_1967',
        ),
      );
      await tester.scrollUntilVisible(
        resultTile,
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(resultTile);
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(FilledButton, 'Guardar libro');
      await tester.scrollUntilVisible(
        saveButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(repository.addedBook, isNull);
      expect(find.text('Este libro ya está en tu biblioteca'), findsOneWidget);
    },
  );
}

Finder _searchField() => find.byType(TextField).first;

Finder _semanticsWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == label,
    description: 'Semantics with label "$label"',
  );
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Book _book({
  required String id,
  required String title,
  required int currentPage,
  required DateTime updatedAt,
}) {
  return Book(
    id: id,
    title: title,
    author: 'Autora',
    totalPages: 200,
    currentPage: currentPage,
    status: BookStatus.reading,
    startDate: DateTime(2026, 6, 1),
    createdAt: DateTime(2026, 5, 1),
    updatedAt: updatedAt,
  );
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
  _CapturingBookRepository({this.existingBooks = const []});

  final List<Book> existingBooks;
  Book? addedBook;

  @override
  Future<void> addBook(Book book) async {
    addedBook = book;
  }

  @override
  Future<void> deleteBook(String id) async {}

  @override
  Future<List<Book>> getAllBooks() async => existingBooks;

  @override
  Future<Book?> getBookById(String id) async => null;

  @override
  Future<void> updateBook(Book book) async {}

  @override
  Stream<List<Book>> watchBooks() => Stream.value(const []);
}

class _BooksRepository implements BookRepository {
  const _BooksRepository(this.books);

  final List<Book> books;

  @override
  Future<void> addBook(Book book) async {}

  @override
  Future<void> deleteBook(String id) async {}

  @override
  Future<List<Book>> getAllBooks() async => books;

  @override
  Future<Book?> getBookById(String id) async =>
      books.where((book) => book.id == id).firstOrNull;

  @override
  Future<void> updateBook(Book book) async {}

  @override
  Stream<List<Book>> watchBooks() => Stream.value(books);
}

class _EmptyStatisticsRepository implements StatisticsRepository {
  const _EmptyStatisticsRepository();

  @override
  Future<StatisticsSummary> getSummary() async =>
      const StatisticsSummary.empty();
}

class _EmptyReadingSessionRepository implements ReadingSessionRepository {
  const _EmptyReadingSessionRepository();

  @override
  Future<void> addSession(ReadingSession session) async {}

  @override
  Future<void> deleteSession(String id) async {}

  @override
  Future<List<ReadingSession>> getSessionsForBook(String bookId) async =>
      const [];

  @override
  Future<List<ReadingSession>> getSessionsForDay(DateTime day) async =>
      const [];

  @override
  Future<List<ReadingSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async => const [];

  @override
  Future<void> updateSession(ReadingSession session) async {}

  @override
  Stream<List<ReadingSession>> watchSessionsInRange(
    DateTime start,
    DateTime end,
  ) => Stream.value(const []);
}
