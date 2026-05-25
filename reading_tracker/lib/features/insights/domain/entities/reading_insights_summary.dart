class ReadingInsightsSummary {
  const ReadingInsightsSummary({
    this.mostReadBookTitle,
    this.mostReadBookPages = 0,
    this.mostReadAuthor,
    this.mostReadAuthorPages = 0,
    this.favoriteGenre,
    this.favoriteGenrePages = 0,
    this.averagePagesPerSession,
    this.averageMinutesPerSession,
    this.averagePagesPerActiveDay,
    this.finishPredictionBookTitle,
    this.finishPredictionRemainingPages,
    this.finishPredictionRecentPagesPerDay,
    this.finishPredictionDaysRemaining,
    this.finishPredictionDate,
    this.completedBooksThisYear = 0,
    this.annualBooksForecast,
    this.topRatedBookTitle,
    this.topRatedBookRating,
    this.longestBookTitle,
    this.longestBookPages,
    this.mostTimeBookTitle,
    this.mostTimeBookMinutes,
    this.mostSessionsBookTitle,
    this.mostSessionsCount,
    this.topAuthors = const [],
    this.topGenres = const [],
    this.topBooks = const [],
    this.bestStreakDays = 0,
  });

  const ReadingInsightsSummary.empty()
    : mostReadBookTitle = null,
      mostReadBookPages = 0,
      mostReadAuthor = null,
      mostReadAuthorPages = 0,
      favoriteGenre = null,
      favoriteGenrePages = 0,
      averagePagesPerSession = null,
      averageMinutesPerSession = null,
      averagePagesPerActiveDay = null,
      finishPredictionBookTitle = null,
      finishPredictionRemainingPages = null,
      finishPredictionRecentPagesPerDay = null,
      finishPredictionDaysRemaining = null,
      finishPredictionDate = null,
      completedBooksThisYear = 0,
      annualBooksForecast = null,
      topRatedBookTitle = null,
      topRatedBookRating = null,
      longestBookTitle = null,
      longestBookPages = null,
      mostTimeBookTitle = null,
      mostTimeBookMinutes = null,
      mostSessionsBookTitle = null,
      mostSessionsCount = null,
      topAuthors = const [],
      topGenres = const [],
      topBooks = const [],
      bestStreakDays = 0;

  final String? mostReadBookTitle;
  final int mostReadBookPages;
  final String? mostReadAuthor;
  final int mostReadAuthorPages;
  final String? favoriteGenre;
  final int favoriteGenrePages;
  final double? averagePagesPerSession;
  final double? averageMinutesPerSession;
  final double? averagePagesPerActiveDay;
  final String? finishPredictionBookTitle;
  final int? finishPredictionRemainingPages;
  final double? finishPredictionRecentPagesPerDay;
  final int? finishPredictionDaysRemaining;
  final DateTime? finishPredictionDate;
  final int completedBooksThisYear;
  final int? annualBooksForecast;
  final String? topRatedBookTitle;
  final double? topRatedBookRating;
  final String? longestBookTitle;
  final int? longestBookPages;
  final String? mostTimeBookTitle;
  final int? mostTimeBookMinutes;
  final String? mostSessionsBookTitle;
  final int? mostSessionsCount;
  final List<ReadingInsightRankingItem> topAuthors;
  final List<ReadingInsightRankingItem> topGenres;
  final List<ReadingInsightRankingItem> topBooks;
  final int bestStreakDays;

  bool get hasReadingActivity =>
      mostReadBookPages > 0 ||
      mostReadAuthorPages > 0 ||
      favoriteGenrePages > 0;

  bool get hasReadingPace =>
      averagePagesPerSession != null ||
      averageMinutesPerSession != null ||
      averagePagesPerActiveDay != null;

  bool get hasFinishPrediction =>
      finishPredictionBookTitle != null &&
      finishPredictionRemainingPages != null &&
      finishPredictionDaysRemaining != null &&
      finishPredictionDate != null;

  bool get hasAnnualForecast => annualBooksForecast != null;

  bool get hasTopReadsOfYear =>
      topRatedBookTitle != null ||
      longestBookTitle != null ||
      mostTimeBookTitle != null ||
      mostSessionsBookTitle != null;

  bool get hasPersonalRanking =>
      topAuthors.isNotEmpty ||
      topGenres.isNotEmpty ||
      topBooks.isNotEmpty ||
      bestStreakDays > 0;

  bool get hasAnyInsight =>
      hasReadingActivity ||
      hasReadingPace ||
      hasFinishPrediction ||
      hasAnnualForecast ||
      hasTopReadsOfYear ||
      hasPersonalRanking;
}

class ReadingInsightRankingItem {
  const ReadingInsightRankingItem({required this.label, required this.value});

  final String label;
  final int value;
}
