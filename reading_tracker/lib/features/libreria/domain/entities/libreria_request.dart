class LibreriaRequest {
  const LibreriaRequest({
    required this.message,
    this.origin,
    this.bookId,
    this.periodStart,
    this.periodEnd,
  });

  final String message;
  final String? origin;
  final String? bookId;
  final DateTime? periodStart;
  final DateTime? periodEnd;
}
