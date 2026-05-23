class StatisticsSummary {
  const StatisticsSummary({
    required this.totalBooks,
    required this.completedBooks,
    required this.readingBooks,
    required this.pausedBooks,
    required this.abandonedBooks,
    required this.toReadBooks,
    required this.totalPagesRead,
    required this.averageRating,
    required this.currentlyReadingCount,
    required this.annualReadingGoal,
    required this.completedThisYear,
    required this.annualGoalProgress,
    required this.booksRemainingForAnnualGoal,
    required this.isAnnualGoalReached,
  });

  const StatisticsSummary.empty()
    : totalBooks = 0,
      completedBooks = 0,
      readingBooks = 0,
      pausedBooks = 0,
      abandonedBooks = 0,
      toReadBooks = 0,
      totalPagesRead = 0,
      averageRating = null,
      currentlyReadingCount = 0,
      annualReadingGoal = null,
      completedThisYear = 0,
      annualGoalProgress = null,
      booksRemainingForAnnualGoal = null,
      isAnnualGoalReached = false;

  final int totalBooks;
  final int completedBooks;
  final int readingBooks;
  final int pausedBooks;
  final int abandonedBooks;
  final int toReadBooks;
  final int totalPagesRead;
  final double? averageRating;
  final int currentlyReadingCount;
  final int? annualReadingGoal;
  final int completedThisYear;
  final double? annualGoalProgress;
  final int? booksRemainingForAnnualGoal;
  final bool isAnnualGoalReached;
}
