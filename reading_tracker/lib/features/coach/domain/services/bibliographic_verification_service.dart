import '../../../books/domain/entities/book.dart';
import '../../../books/domain/entities/book_search_result.dart';
import '../../../books/domain/services/book_duplicate_matcher.dart';
import '../models/bibliographic_candidate.dart';
import '../models/recommendation_constraints.dart';

class BibliographicVerificationResult {
  BibliographicVerificationResult({
    required List<BibliographicCandidate> verifiedCandidates,
    required Set<String> blockingFields,
  }) : verifiedCandidates = List.unmodifiable(verifiedCandidates),
       blockingFields = Set.unmodifiable(blockingFields);

  final List<BibliographicCandidate> verifiedCandidates;
  final Set<String> blockingFields;
}

class BibliographicVerificationService {
  const BibliographicVerificationService({
    this.duplicateMatcher = const BookDuplicateMatcher(),
  });

  final BookDuplicateMatcher duplicateMatcher;

  BibliographicVerificationResult verify({
    required List<BookSearchResult> results,
    required RecommendationConstraints constraints,
    required List<Book> library,
    int limit = 3,
  }) {
    final verified = <BibliographicCandidate>[];
    final blockers = <String>{};

    for (final result in results) {
      final evidence = <BibliographicEvidence>[
        BibliographicEvidence(
          field: 'existencia',
          level: result.title.trim().isEmpty
              ? BibliographicVerificationLevel.conflicting
              : BibliographicVerificationLevel.verified,
          value: result.title.trim(),
          source: result.externalSource ?? 'fuente bibliografica',
          isMandatory: true,
        ),
      ];
      final source = result.externalSource ?? 'fuente bibliografica';
      evidence.addAll([
        _availableEvidence('autoria', result.author, source),
        _availableEvidence('ISBN', result.isbn, source),
        _availableEvidence(
          'categorias',
          result.categories.isEmpty ? null : result.categories.join(', '),
          source,
        ),
        _availableEvidence('descripcion', result.description, source),
        _availableEvidence('idioma bibliografico', result.language, source),
        _availableEvidence(
          'fecha de publicacion',
          result.firstPublishYear?.toString(),
          source,
        ),
        const BibliographicEvidence(
          field: 'pertenencia a serie',
          level: BibliographicVerificationLevel.notVerified,
          source: 'no disponible en la fuente',
        ),
        const BibliographicEvidence(
          field: 'posicion en serie',
          level: BibliographicVerificationLevel.notVerified,
          source: 'no disponible en la fuente',
        ),
        const BibliographicEvidence(
          field: 'disponibilidad',
          level: BibliographicVerificationLevel.notVerified,
          source: 'sin catalogo de disponibilidad',
        ),
      ]);

      if (constraints.outsideLibrary) {
        final duplicate = duplicateMatcher.findDuplicate(result, library);
        evidence.add(
          BibliographicEvidence(
            field: 'fuera de la biblioteca',
            level: duplicate == null
                ? BibliographicVerificationLevel.verified
                : BibliographicVerificationLevel.conflicting,
            value: duplicate?.status.label,
            source: 'biblioteca local completa',
            isMandatory: true,
          ),
        );
      }
      if (constraints.genre != null) {
        evidence.add(
          _matchListEvidence(
            field: 'genero',
            expected: constraints.genre!,
            values: result.categories,
            source: source,
            isMandatory: true,
          ),
        );
      }
      if (constraints.language != null) {
        final actual = result.language?.trim();
        evidence.add(
          BibliographicEvidence(
            field: 'idioma',
            level: actual == null || actual.isEmpty
                ? BibliographicVerificationLevel.notVerified
                : normalizeRecommendationText(actual) ==
                          normalizeRecommendationText(constraints.language!)
                      ? BibliographicVerificationLevel.verified
                      : BibliographicVerificationLevel.conflicting,
            value: actual,
            source: source,
            isMandatory: true,
          ),
        );
      }
      if (constraints.maxPages != null) {
        final pages = result.numberOfPages;
        evidence.add(
          BibliographicEvidence(
            field: 'maximo de paginas',
            level: pages == null
                ? BibliographicVerificationLevel.notVerified
                : pages <= constraints.maxPages!
                    ? BibliographicVerificationLevel.verified
                    : BibliographicVerificationLevel.conflicting,
            value: pages?.toString(),
            source: source,
            isMandatory: true,
          ),
        );
      }
      if (constraints.standalone) {
        evidence.add(
          BibliographicEvidence(
            field: 'autoconclusivo',
            level: BibliographicVerificationLevel.notVerified,
            source: source,
            isMandatory: true,
          ),
        );
      }
      if (constraints.completedSeries) {
        evidence.add(
          BibliographicEvidence(
            field: 'saga terminada',
            level: BibliographicVerificationLevel.notVerified,
            source: source,
            isMandatory: true,
          ),
        );
      }
      if (constraints.authorGender != null) {
        evidence.add(
          BibliographicEvidence(
            field: 'genero de autoria',
            level: BibliographicVerificationLevel.notVerified,
            value: result.author,
            source: source,
            isMandatory: true,
          ),
        );
      }
      if (constraints.format != null) {
        evidence.add(
          BibliographicEvidence(
            field: 'formato',
            level: BibliographicVerificationLevel.notVerified,
            source: source,
            isMandatory: true,
          ),
        );
      }
      if (constraints.avoidedTrope != null) {
        evidence.add(
          BibliographicEvidence(
            field: 'tropo evitado',
            level: BibliographicVerificationLevel.notVerified,
            source: source,
            isMandatory: true,
          ),
        );
      }

      final candidate = BibliographicCandidate(
        title: result.title.trim(),
        normalizedTitle: normalizeBookText(result.title),
        authors: result.author?.trim().isNotEmpty == true
            ? [result.author!.trim()]
            : const [],
        isbn: normalizeBookIdentifier(result.isbn).isEmpty
            ? null
            : normalizeBookIdentifier(result.isbn),
        categories: List.unmodifiable(result.categories),
        description: result.description,
        language: result.language,
        pageCount: result.numberOfPages,
        publishedYear: result.firstPublishYear,
        source: source,
        evidence: evidence,
      );
      if (candidate.satisfiesAllMandatory) {
        if (verified.length < limit) verified.add(candidate);
      } else {
        blockers.addAll(
          evidence
              .where(
                (item) =>
                    item.isMandatory &&
                    item.level != BibliographicVerificationLevel.verified,
              )
              .map((item) => item.field),
        );
      }
    }

    return BibliographicVerificationResult(
      verifiedCandidates: verified,
      blockingFields: blockers,
    );
  }

  BibliographicEvidence _matchListEvidence({
    required String field,
    required String expected,
    required List<String> values,
    required String source,
    bool isMandatory = true,
  }) {
    if (values.isEmpty) {
      return BibliographicEvidence(
        field: field,
        level: BibliographicVerificationLevel.notVerified,
        source: source,
        isMandatory: isMandatory,
      );
    }
    final normalizedExpected = normalizeRecommendationText(expected);
    final expectedAliases = _genreAliases(normalizedExpected);
    final matches = values.any((value) {
      final normalized = normalizeRecommendationText(value);
      return expectedAliases.any(
        (alias) => normalized.contains(alias) || alias.contains(normalized),
      );
    });
    return BibliographicEvidence(
      field: field,
      level: matches
          ? BibliographicVerificationLevel.verified
          : BibliographicVerificationLevel.conflicting,
      value: values.join(', '),
      source: source,
      isMandatory: isMandatory,
    );
  }

  Set<String> _genreAliases(String value) => switch (value) {
    'fantasia' => const {'fantasia', 'fantasy'},
    'ciencia ficcion' => const {'ciencia ficcion', 'science fiction', 'sci fi'},
    'romance' => const {'romance', 'romantic fiction'},
    _ => {value},
  };

  BibliographicEvidence _availableEvidence(
    String field,
    String? value,
    String source,
  ) {
    final normalized = value?.trim();
    return BibliographicEvidence(
      field: field,
      level: normalized == null || normalized.isEmpty
          ? BibliographicVerificationLevel.notVerified
          : BibliographicVerificationLevel.verified,
      value: normalized,
      source: source,
    );
  }
}
