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
      currentlyReadingCount = 0;

  final int totalBooks;
  final int completedBooks;
  final int readingBooks;
  final int pausedBooks;
  final int abandonedBooks;
  final int toReadBooks;
  final int totalPagesRead;
  final double? averageRating;
  final int currentlyReadingCount;
}
