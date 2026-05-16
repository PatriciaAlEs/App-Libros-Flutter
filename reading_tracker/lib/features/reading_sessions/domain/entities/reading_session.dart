class ReadingSession {
  const ReadingSession({
    required this.id,
    required this.bookId,
    required this.date,
    required this.minutes,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String bookId;
  final DateTime date;
  final int minutes;
  final String? note;
  final DateTime createdAt;

  ReadingSession copyWith({
    String? id,
    String? bookId,
    DateTime? date,
    int? minutes,
    String? note,
    DateTime? createdAt,
  }) {
    return ReadingSession(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      date: date ?? this.date,
      minutes: minutes ?? this.minutes,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
