import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/core/preferences/reader_profile_controller.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/coach/domain/models/reader_context.dart';
import 'package:reading_tracker/features/coach/domain/services/context_formatter.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';

void main() {
  group('MarkdownContextFormatter', () {
    const formatter = MarkdownContextFormatter();

    test('formats an empty context with only metadata', () {
      final markdown = formatter.format(_context());

      expect(markdown, '# Contexto\n\n- Generado: 2026-07-09 10:30');
      expect(markdown, isNot(contains('# Perfil lector')));
      expect(markdown, isNot(contains('# Objetivo anual')));
      expect(markdown, isNot(contains('# Biblioteca')));
      expect(markdown, isNot(contains('# Actividad')));
    });

    test('formats useful library information for a user with books', () {
      final markdown = formatter.format(
        _context(
          books: [
            _book(
              'current-old',
              'Current Old',
              status: BookStatus.reading,
              updatedAt: DateTime(2026, 7, 3),
            ),
            _book(
              'current-new',
              'Current New',
              author: 'Author A',
              status: BookStatus.reading,
              currentPage: 80,
              totalPages: 200,
              updatedAt: DateTime(2026, 7, 8),
            ),
            _book(
              'completed',
              'Completed Book',
              status: BookStatus.completed,
              rating: 4.5,
              completedDate: DateTime(2026, 7, 1),
            ),
            _book(
              'pending',
              'Pending Book',
              status: BookStatus.pending,
              createdAt: DateTime(2026, 7, 6),
            ),
            _book('abandoned', 'Abandoned Book', status: BookStatus.abandoned),
          ],
        ),
      );

      expect(markdown, contains('# Biblioteca'));
      expect(markdown, contains('## Libros en lectura'));
      expect(markdown, contains('- Current New (Author A, 80/200 pags.)'));
      expect(
        markdown.indexOf('Current New'),
        lessThan(markdown.indexOf('Current Old')),
      );
      expect(markdown, contains('## Ultimos libros terminados'));
      expect(
        markdown,
        contains('- Completed Book (valoracion 4.5, terminado 2026-07-01)'),
      );
      expect(markdown, contains('## Pendientes'));
      expect(markdown, contains('- Pending Book'));
      expect(markdown, contains('## Abandonados'));
      expect(markdown, contains('- Abandoned Book'));
    });

    test('includes real preference and verification signals from books', () {
      final markdown = formatter.format(
        _context(
          books: [
            _book(
              'verified-book',
              'Verified Book',
              author: 'Known Author',
              status: BookStatus.completed,
              genre: 'Fantasia',
              notes: 'Personajes memorables',
              publisher: 'Editorial Real',
              isbn: '9780000000001',
            ),
          ],
        ),
      );

      expect(markdown, contains('genero Fantasia'));
      expect(markdown, contains('notas: Personajes memorables'));
      expect(markdown, contains('editorial Editorial Real'));
      expect(markdown, contains('ISBN 9780000000001'));
    });

    test('limits long book lists to useful entries', () {
      final books = List.generate(
        8,
        (index) => _book(
          'book-$index',
          'Current $index',
          status: BookStatus.reading,
          updatedAt: DateTime(2026, 7, index + 1),
        ),
      );

      final markdown = formatter.format(_context(books: books));

      expect(markdown, contains('Current 7'));
      expect(markdown, contains('Current 3'));
      expect(markdown, isNot(contains('Current 2')));
      expect(markdown, isNot(contains('Current 0')));
    });

    test('formats activity from reading sessions', () {
      final markdown = formatter.format(
        _context(
          sessions: [
            _session(
              'session-1',
              'book-1',
              DateTime(2026, 7, 7),
              pagesRead: 10,
            ),
            _session('session-2', 'book-2', DateTime(2026, 7, 8), minutes: 45),
          ],
        ),
      );

      expect(markdown, contains('# Actividad'));
      expect(markdown, contains('- Sesiones registradas: 2'));
      expect(markdown, contains('- Minutos leidos: 75'));
      expect(markdown, contains('- Paginas registradas: 10'));
      expect(markdown, contains('## Sesiones recientes'));
      expect(markdown.indexOf('session'), -1);
      expect(
        markdown.indexOf('2026-07-08'),
        lessThan(markdown.indexOf('2026-07-07')),
      );
      expect(markdown, contains('- 2026-07-08, 45 min - libro book-2'));
      expect(
        markdown,
        contains('- 2026-07-07, 30 min, 10 pags. - libro book-1'),
      );
    });

    test('resolves activity book ids to real library titles', () {
      final markdown = formatter.format(
        _context(
          books: [_book('book-1', 'Titulo conocido')],
          sessions: [_session('session-1', 'book-1', DateTime(2026, 7, 8))],
        ),
      );

      expect(markdown, contains('libro Titulo conocido'));
      expect(markdown, isNot(contains('libro book-1')));
    });

    test('formats annual goal', () {
      final markdown = formatter.format(_context(annualReadingGoal: 24));

      expect(markdown, contains('# Objetivo anual'));
      expect(markdown, contains('- Meta de libros: 24'));
    });

    test('formats useful reader profile fields', () {
      final markdown = formatter.format(
        _context(
          readerProfile: const ReaderProfile(
            name: 'Patri',
            customGreeting: 'Capitana',
            greetingPreference: ReaderGreetingPreference.custom,
            currentReadingBookId: 'book-1',
          ),
        ),
      );

      expect(markdown, contains('# Perfil lector'));
      expect(markdown, contains('- Nombre: Patri'));
      expect(markdown, contains('- Saludo preferido: Capitana'));
      expect(markdown, contains('- Libro actual destacado: book-1'));
    });

    test('omits optional fields and empty titles', () {
      final markdown = formatter.format(
        _context(
          readerProfile: const ReaderProfile(),
          books: [
            _book('empty-title', '   ', status: BookStatus.reading),
            _book('visible', 'Visible Book', status: BookStatus.completed),
          ],
          sessions: [_session('session-1', 'book-1', DateTime(2026, 7, 8))],
        ),
      );

      expect(markdown, isNot(contains('# Perfil lector')));
      expect(markdown, isNot(contains('empty-title')));
      expect(markdown, isNot(contains('   ')));
      expect(markdown, contains('Visible Book'));
      expect(markdown, isNot(contains('Paginas registradas: 0')));
    });

    test('uses Markdown headings', () {
      final markdown = formatter.format(
        _context(
          readerProfile: const ReaderProfile(name: 'Patri'),
          annualReadingGoal: 12,
          books: [_book('book-1', 'Book One', status: BookStatus.reading)],
          sessions: [_session('session-1', 'book-1', DateTime(2026, 7, 8))],
        ),
      );

      expect(markdown, startsWith('# Contexto'));
      expect(markdown, contains('\n\n# Perfil lector\n'));
      expect(markdown, contains('\n\n# Objetivo anual\n'));
      expect(markdown, contains('\n\n# Biblioteca\n'));
      expect(markdown, contains('\n\n# Actividad\n'));
    });

    test('produces deterministic output for the same context', () {
      final context = _context(
        books: [
          _book('b', 'Beta', status: BookStatus.completed),
          _book('a', 'Alpha', status: BookStatus.reading),
        ],
        sessions: [
          _session('session-2', 'b', DateTime(2026, 7, 8)),
          _session('session-1', 'a', DateTime(2026, 7, 8)),
        ],
        annualReadingGoal: 10,
      );

      final first = formatter.format(context);
      final second = formatter.format(context);

      expect(second, first);
    });
  });
}

ReaderContext _context({
  List<Book> books = const [],
  List<ReadingSession> sessions = const [],
  int? annualReadingGoal,
  ReaderProfile? readerProfile,
}) {
  return ReaderContext(
    metadata: ReaderContextMetadata(generatedAt: DateTime(2026, 7, 9, 10, 30)),
    library: ReaderLibraryContext(
      allBooks: books,
      currentBooks: books
          .where((book) => book.status == BookStatus.reading)
          .toList(),
      completedBooks: books
          .where((book) => book.status == BookStatus.completed)
          .toList(),
      pendingBooks: books
          .where((book) => book.status == BookStatus.pending)
          .toList(),
      abandonedBooks: books
          .where((book) => book.status == BookStatus.abandoned)
          .toList(),
    ),
    activity: ReaderActivityContext(readingSessions: sessions),
    annualReadingGoal: annualReadingGoal,
    readerProfile: readerProfile,
  );
}

Book _book(
  String id,
  String title, {
  BookStatus status = BookStatus.pending,
  String? author,
  int? currentPage,
  int? totalPages,
  double? rating,
  String? genre,
  String? notes,
  String? publisher,
  String? isbn,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? completedDate,
}) {
  return Book(
    id: id,
    title: title,
    author: author,
    currentPage: currentPage,
    totalPages: totalPages,
    rating: rating,
    genre: genre,
    notes: notes,
    publisher: publisher,
    isbn: isbn,
    status: status,
    createdAt: createdAt ?? DateTime(2026, 7, 1),
    updatedAt: updatedAt,
    completedDate: completedDate,
  );
}

ReadingSession _session(
  String id,
  String bookId,
  DateTime date, {
  int minutes = 30,
  int pagesRead = 0,
}) {
  return ReadingSession(
    id: id,
    bookId: bookId,
    date: date,
    minutes: minutes,
    pagesRead: pagesRead,
    createdAt: date,
  );
}
