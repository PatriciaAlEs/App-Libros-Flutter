class BookSearchResult {
  const BookSearchResult({
    required this.title,
    this.author,
    this.publisher,
    this.coverUrl,
    this.isbn,
    this.firstPublishYear,
  });

  final String title;
  final String? author;
  final String? publisher;
  final String? coverUrl;
  final String? isbn;
  final int? firstPublishYear;
}
