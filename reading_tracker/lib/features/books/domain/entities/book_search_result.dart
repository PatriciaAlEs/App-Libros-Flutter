class BookSearchResult {
  const BookSearchResult({
    required this.title,
    this.author,
    this.publisher,
    this.coverUrl,
    this.isbn,
    this.externalSource,
    this.externalId,
    this.firstPublishYear,
    this.numberOfPages,
    this.categories = const [],
    this.description,
    this.language,
  });

  final String title;
  final String? author;
  final String? publisher;
  final String? coverUrl;
  final String? isbn;
  final String? externalSource;
  final String? externalId;
  final int? firstPublishYear;
  final int? numberOfPages;
  final List<String> categories;
  final String? description;
  final String? language;
}
