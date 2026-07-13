import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/entities/book_search_result.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/domain/models/bibliographic_candidate.dart';
import 'package:reading_tracker/features/coach/domain/models/reader_context.dart';
import 'package:reading_tracker/features/coach/domain/models/recommendation_constraints.dart';
import 'package:reading_tracker/features/coach/domain/services/bibliographic_recommendation_service.dart';
import 'package:reading_tracker/features/coach/domain/services/bibliographic_search_service.dart';
import 'package:reading_tracker/features/coach/domain/services/bibliographic_verification_service.dart';

void main() {
  group('RecommendationConstraintExtractor', () {
    const extractor = RecommendationConstraintExtractor();

    test('activa busqueda externa y acumula el seguimiento exacto de QA', () {
      final constraints = extractor.extract(
        userMessage:
            'Además debe ser autoconclusiva y estar escrita por una mujer.',
        conversation: [
          CoachMessage.user(
            'Quiero una fantasía cerrada y que no esté en mi biblioteca.',
          ),
        ],
      );

      expect(constraints.requiresExternalSearch, isTrue);
      expect(constraints.outsideLibrary, isTrue);
      expect(constraints.genre, 'fantasia');
      expect(constraints.completedSeries, isTrue);
      expect(constraints.standalone, isTrue);
      expect(constraints.authorGender, 'mujer');
    });

    test('una pregunta de progreso no activa busqueda', () {
      final constraints = extractor.extract(
        userMessage: '¿Cuántas páginas llevo este mes?',
        conversation: const [],
      );

      expect(constraints.requiresExternalSearch, isFalse);
    });

    test('permite retirar una restriccion de saga', () {
      final constraints = extractor.extract(
        userMessage: 'Da igual que sea una saga.',
        conversation: [
          CoachMessage.user(
            'Quiero una fantasía autoconclusiva fuera de mi biblioteca.',
          ),
        ],
      );

      expect(constraints.requiresExternalSearch, isTrue);
      expect(constraints.standalone, isFalse);
      expect(constraints.completedSeries, isFalse);
    });
  });

  group('BibliographicVerificationService', () {
    const verifier = BibliographicVerificationService();

    test('normaliza candidatos y verifica genero y ausencia local', () {
      final result = verifier.verify(
        results: const [
          BookSearchResult(
            title: 'La Canción Oscura',
            author: 'Autora Real',
            isbn: '978-1-2345-6789-0',
            externalSource: 'open_library',
            categories: ['Fantasy'],
          ),
        ],
        constraints: const RecommendationConstraints(
          requiresExternalSearch: true,
          outsideLibrary: true,
          genre: 'fantasia',
        ),
        library: const [],
      );

      expect(result.verifiedCandidates, hasLength(1));
      expect(result.verifiedCandidates.single.normalizedTitle, 'la cancion oscura');
      expect(result.verifiedCandidates.single.isbn, '9781234567890');
    });

    test('excluye por ISBN en cualquier estado de biblioteca', () {
      for (final status in BookStatus.values) {
        final result = verifier.verify(
          results: const [
            BookSearchResult(
              title: 'Otra edición',
              author: 'Autora',
              isbn: '9781234567890',
              externalSource: 'open_library',
            ),
          ],
          constraints: const RecommendationConstraints(
            requiresExternalSearch: true,
            outsideLibrary: true,
          ),
          library: [_book('Local', 'Autora', status, isbn: '978-1-2345-6789-0')],
        );

        expect(result.verifiedCandidates, isEmpty, reason: status.name);
        expect(result.blockingFields, contains('fuera de la biblioteca'));
      }
    });

    test('excluye por titulo y autoria cuando no hay ISBN', () {
      final result = verifier.verify(
        results: const [
          BookSearchResult(
            title: 'Título, idéntico!',
            author: 'Nombre Autora',
            externalSource: 'google_books',
          ),
        ],
        constraints: const RecommendationConstraints(
          requiresExternalSearch: true,
          outsideLibrary: true,
        ),
        library: [_book('Titulo identico', 'Nombre Autora', BookStatus.pending)],
      );

      expect(result.verifiedCandidates, isEmpty);
    });

    test('mantiene metadatos ausentes como notVerified', () {
      final result = verifier.verify(
        results: const [
          BookSearchResult(
            title: 'Libro existente',
            author: 'Nombre Persona',
            externalSource: 'open_library',
          ),
        ],
        constraints: const RecommendationConstraints(
          requiresExternalSearch: true,
          standalone: true,
          authorGender: 'mujer',
        ),
        library: const [],
      );

      expect(result.verifiedCandidates, isEmpty);
      expect(result.blockingFields, containsAll(['autoconclusivo', 'genero de autoria']));
    });

    test('un metadato en conflicto descarta el candidato', () {
      final result = verifier.verify(
        results: const [
          BookSearchResult(
            title: 'Novela histórica',
            categories: ['History'],
            externalSource: 'google_books',
          ),
        ],
        constraints: const RecommendationConstraints(
          requiresExternalSearch: true,
          genre: 'fantasia',
        ),
        library: const [],
      );

      expect(result.verifiedCandidates, isEmpty);
      expect(result.blockingFields, contains('genero'));
    });

    test('no confunde saga completa con autoconclusivo', () {
      final result = verifier.verify(
        results: const [
          BookSearchResult(
            title: 'Libro de una trilogía',
            author: 'Autor',
            externalSource: 'open_library',
          ),
        ],
        constraints: const RecommendationConstraints(
          requiresExternalSearch: true,
          completedSeries: true,
          standalone: true,
        ),
        library: const [],
      );

      expect(result.verifiedCandidates, isEmpty);
      expect(result.blockingFields, containsAll(['saga terminada', 'autoconclusivo']));
    });
  });

  group('BibliographicRecommendationService', () {
    test('no consulta la fuente para progreso', () async {
      final search = _FakeSearchService(const []);
      final service = BibliographicRecommendationService(searchService: search);

      final context = await service.prepareContext(
        userMessage: 'Resume mi progreso lector',
        conversation: const [],
        readerContext: _context(),
      );

      expect(context, isNull);
      expect(search.queries, isEmpty);
    });

    test('inyecta solo candidatos que superan todos los filtros', () async {
      final search = _FakeSearchService(const [
        BookSearchResult(
          title: 'Candidato verificado',
          author: 'Autora',
          categories: ['Fantasy'],
          externalSource: 'open_library',
        ),
      ]);
      final service = BibliographicRecommendationService(searchService: search);

      final context = await service.prepareContext(
        userMessage:
            'Recomiéndame un libro de fantasía fuera de mi biblioteca',
        conversation: const [],
        readerContext: _context(),
      );

      expect(search.queries, ['fantasia libro']);
      expect(context, startsWith('# Candidatos bibliográficos verificados'));
      expect(context, contains('Candidato verificado'));
      expect(context, contains('exclusivamente títulos incluidos aquí'));
    });

    test('no envia inventario ni datos privados a la fuente', () async {
      final search = _FakeSearchService(const []);
      final service = BibliographicRecommendationService(searchService: search);

      await service.prepareContext(
        userMessage: 'Quiero fantasía fuera de mi biblioteca',
        conversation: const [],
        readerContext: _context(
          books: [
            Book(
              id: 'private',
              title: 'Título privado',
              notes: 'Nota privada',
              rating: 5,
              createdAt: DateTime(2026),
            ),
          ],
        ),
      );

      expect(search.queries.single, isNot(contains('Título privado')));
      expect(search.queries.single, isNot(contains('Nota privada')));
    });

    test('reutiliza una busqueda identica durante la cache breve', () async {
      final search = _FakeSearchService(const []);
      final service = BibliographicRecommendationService(searchService: search);

      for (var index = 0; index < 2; index++) {
        await service.prepareContext(
          userMessage: 'Quiero fantasía fuera de mi biblioteca',
          conversation: const [],
          readerContext: _context(),
        );
      }

      expect(search.queries, hasLength(1));
    });

    test('gestiona respuesta vacia y timeout sin inventar', () async {
      final emptyService = BibliographicRecommendationService(
        searchService: _FakeSearchService(const []),
      );
      final empty = await emptyService.prepareContext(
        userMessage: 'Quiero fantasía fuera de mi biblioteca',
        conversation: const [],
        readerContext: _context(),
      );
      expect(empty, contains('No he encontrado una opción'));

      final timeoutService = BibliographicRecommendationService(
        searchService: _FailingSearchService(),
      );
      final timeout = await timeoutService.prepareContext(
        userMessage: 'Quiero fantasía fuera de mi biblioteca',
        conversation: const [],
        readerContext: _context(),
      );
      expect(timeout, contains('La fuente bibliográfica no ha respondido'));
    });
  });
}

class _FakeSearchService implements BibliographicSearchService {
  _FakeSearchService(this.results);

  final List<BookSearchResult> results;
  final List<String> queries = [];

  @override
  Future<List<BookSearchResult>> search(String query) async {
    queries.add(query);
    return results;
  }
}

class _FailingSearchService implements BibliographicSearchService {
  @override
  Future<List<BookSearchResult>> search(String query) =>
      Future.error(TimeoutException('timeout'));
}

Book _book(
  String title,
  String author,
  BookStatus status, {
  String? isbn,
}) => Book(
  id: '$title-$status',
  title: title,
  author: author,
  status: status,
  isbn: isbn,
  createdAt: DateTime(2026),
);

ReaderContext _context({List<Book> books = const []}) => ReaderContext(
  metadata: ReaderContextMetadata(generatedAt: DateTime(2026)),
  library: ReaderLibraryContext(
    allBooks: books,
    currentBooks: const [],
    completedBooks: const [],
    pendingBooks: const [],
    abandonedBooks: const [],
  ),
  activity: ReaderActivityContext(readingSessions: const []),
);
