import '../entities/coach_message.dart';
import '../../../books/domain/entities/book_search_result.dart';
import '../models/reader_context.dart';
import '../models/recommendation_constraints.dart';
import 'bibliographic_search_service.dart';
import 'bibliographic_verification_service.dart';
import 'verified_bibliographic_context_formatter.dart';

class BibliographicRecommendationService {
  BibliographicRecommendationService({
    required BibliographicSearchService searchService,
    this.extractor = const RecommendationConstraintExtractor(),
    this.verificationService = const BibliographicVerificationService(),
    this.contextFormatter = const VerifiedBibliographicContextFormatter(),
    this.cacheDuration = const Duration(minutes: 5),
    this.searchTimeout = const Duration(seconds: 10),
    this.now = DateTime.now,
  }) : _searchService = searchService;

  final BibliographicSearchService _searchService;
  final RecommendationConstraintExtractor extractor;
  final BibliographicVerificationService verificationService;
  final VerifiedBibliographicContextFormatter contextFormatter;
  final Duration cacheDuration;
  final Duration searchTimeout;
  final DateTime Function() now;
  final Map<String, ({DateTime at, List<BookSearchResult> results})> _cache = {};

  Future<String?> prepareContext({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
  }) async {
    final constraints = extractor.extract(
      userMessage: userMessage,
      conversation: conversation,
    );
    if (!constraints.requiresExternalSearch) return null;

    final query = _queryFor(constraints);
    try {
      final cached = _cache[query];
      final results = cached != null && now().difference(cached.at) < cacheDuration
          ? cached.results
          : await _searchService.search(query).timeout(searchTimeout);
      _cache[query] = (at: now(), results: results);
      final verification = verificationService.verify(
        results: results,
        constraints: constraints,
        library: readerContext.library.allBooks,
      );
      return contextFormatter.format(
        constraints: constraints,
        result: verification,
      );
    } catch (_) {
      return '# Candidatos bibliográficos verificados\n\n'
          'La fuente bibliográfica no ha respondido. No inventes candidatos ni atribuyas el fallo a la biblioteca de la persona.';
    }
  }

  String _queryFor(RecommendationConstraints constraints) {
    final terms = <String>[
      if (constraints.genre != null) constraints.genre!,
      if (constraints.language != null) constraints.language!,
      'libro',
    ];
    return terms.join(' ');
  }
}
