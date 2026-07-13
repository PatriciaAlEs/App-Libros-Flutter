enum BibliographicVerificationLevel { verified, notVerified, conflicting }

class BibliographicEvidence {
  const BibliographicEvidence({
    required this.field,
    required this.level,
    this.value,
    required this.source,
    this.isMandatory = false,
  });

  final String field;
  final BibliographicVerificationLevel level;
  final String? value;
  final String source;
  final bool isMandatory;
}

class BibliographicCandidate {
  BibliographicCandidate({
    required this.title,
    required this.normalizedTitle,
    required this.authors,
    required this.isbn,
    required this.categories,
    required this.description,
    required this.language,
    required this.pageCount,
    required this.publishedYear,
    required this.source,
    required List<BibliographicEvidence> evidence,
  }) : evidence = List.unmodifiable(evidence);

  final String title;
  final String normalizedTitle;
  final List<String> authors;
  final String? isbn;
  final List<String> categories;
  final String? description;
  final String? language;
  final int? pageCount;
  final int? publishedYear;
  final String source;
  final List<BibliographicEvidence> evidence;

  bool get satisfiesAllMandatory => evidence.every(
    (item) =>
        !item.isMandatory ||
        item.level == BibliographicVerificationLevel.verified,
  );
}
