class ReadingInsightsSummary {
  const ReadingInsightsSummary({
    this.mostReadBookTitle,
    this.mostReadBookPages = 0,
    this.mostReadAuthor,
    this.mostReadAuthorPages = 0,
    this.favoriteGenre,
    this.favoriteGenrePages = 0,
  });

  const ReadingInsightsSummary.empty()
    : mostReadBookTitle = null,
      mostReadBookPages = 0,
      mostReadAuthor = null,
      mostReadAuthorPages = 0,
      favoriteGenre = null,
      favoriteGenrePages = 0;

  final String? mostReadBookTitle;
  final int mostReadBookPages;
  final String? mostReadAuthor;
  final int mostReadAuthorPages;
  final String? favoriteGenre;
  final int favoriteGenrePages;

  bool get hasReadingActivity =>
      mostReadBookPages > 0 ||
      mostReadAuthorPages > 0 ||
      favoriteGenrePages > 0;
}
