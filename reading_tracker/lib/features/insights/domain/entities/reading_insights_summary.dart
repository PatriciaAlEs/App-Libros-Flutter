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
      annualBooksForecast = null;

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

  bool get hasAnyInsight =>
      hasReadingActivity ||
      hasReadingPace ||
      hasFinishPrediction ||
      hasAnnualForecast;
}
