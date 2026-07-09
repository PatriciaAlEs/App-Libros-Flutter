class LibreriaRouteArguments {
  const LibreriaRouteArguments({
    required this.origin,
    this.bookId,
    this.periodStart,
    this.periodEnd,
  });

  final String origin;
  final String? bookId;
  final DateTime? periodStart;
  final DateTime? periodEnd;
}
