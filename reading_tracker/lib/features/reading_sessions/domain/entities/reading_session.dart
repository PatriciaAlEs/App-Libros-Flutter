class ReadingSession {
  const ReadingSession({
    required this.id,
    required this.bookId,
    required this.date,
    required this.minutes,
    required this.createdAt,
    this.pagesRead = 0,
    this.note,
    this.updatedAt,
  });

  final String id;
  final String bookId;
  final DateTime date;
  final int minutes;
  final int pagesRead;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReadingSession copyWith({
    String? id,
    String? bookId,
    DateTime? date,
    int? minutes,
    int? pagesRead,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReadingSession(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      date: date ?? this.date,
      minutes: minutes ?? this.minutes,
      pagesRead: pagesRead ?? this.pagesRead,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
