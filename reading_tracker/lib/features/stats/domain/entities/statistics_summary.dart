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
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.pagesReadThisWeek,
    required this.pagesReadThisMonth,
    required this.minutesReadThisWeek,
    required this.minutesReadThisMonth,
    required this.averagePagesPerActiveDay,
    required this.averageMinutesPerActiveDay,
    required this.mostActiveDayDate,
    required this.mostActiveDayPages,
    required this.mostActiveDayMinutes,
    required this.activeDaysThisMonth,
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
      isAnnualGoalReached = false,
      currentStreakDays = 0,
      bestStreakDays = 0,
      pagesReadThisWeek = 0,
      pagesReadThisMonth = 0,
      minutesReadThisWeek = 0,
      minutesReadThisMonth = 0,
      averagePagesPerActiveDay = 0,
      averageMinutesPerActiveDay = 0,
      mostActiveDayDate = null,
      mostActiveDayPages = 0,
      mostActiveDayMinutes = 0,
      activeDaysThisMonth = 0;

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
  final int currentStreakDays;
  final int bestStreakDays;
  final int pagesReadThisWeek;
  final int pagesReadThisMonth;
  final int minutesReadThisWeek;
  final int minutesReadThisMonth;
  final double averagePagesPerActiveDay;
  final double averageMinutesPerActiveDay;
  final DateTime? mostActiveDayDate;
  final int mostActiveDayPages;
  final int mostActiveDayMinutes;
  final int activeDaysThisMonth;
}
